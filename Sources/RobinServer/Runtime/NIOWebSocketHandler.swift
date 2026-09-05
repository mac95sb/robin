import NIOCore
import NIOWebSocket

// Mutable handler state stays on the channel's event loop; the session task captures only sendable values.
final class NIOWebSocketHandler: ChannelInboundHandler, @unchecked Sendable {
  typealias InboundIn = WebSocketFrame
  static let maximumPendingMessages = 32

  private let session: WebSocketSession
  private var continuation: AsyncStream<WebSocketMessage>.Continuation?
  private var task: Task<Void, Never>?

  init(session: WebSocketSession) {
    self.session = session
  }

  func handlerAdded(context: ChannelHandlerContext) {
    let (messages, continuation) = AsyncStream.makeStream(
      of: WebSocketMessage.self,
      bufferingPolicy: .bufferingOldest(Self.maximumPendingMessages))
    self.continuation = continuation
    let channel = context.channel
    let connection = WebSocketConnection(
      send: { message in
        let frame: WebSocketFrame
        switch message {
        case .text(let text):
          frame = WebSocketFrame(fin: true, opcode: .text, data: ByteBuffer(string: text))
        case .binary(let bytes):
          frame = WebSocketFrame(fin: true, opcode: .binary, data: ByteBuffer(bytes: bytes))
        }
        try await channel.writeAndFlush(frame).get()
      },
      close: {
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: ByteBuffer())
        try await channel.writeAndFlush(frame).get()
        try await channel.close()
      }
    )
    task = Task { [session] in
      do {
        try await session.operation(connection, messages)
      } catch is CancellationError {
      } catch {
        try? await connection.close()
      }
    }
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let frame = unwrapInboundIn(data)
    var payload = frame.unmaskedData
    switch frame.opcode {
    case .text:
      yield(
        .text(payload.readString(length: payload.readableBytes) ?? ""), context: context)
    case .binary:
      yield(.binary(Array(payload.readableBytesView)), context: context)
    case .ping:
      context.channel.writeAndFlush(
        WebSocketFrame(fin: true, opcode: .pong, data: payload),
        promise: nil
      )
    case .connectionClose:
      continuation?.finish()
      context.close(promise: nil)
    default:
      break
    }
  }

  private func yield(_ message: WebSocketMessage, context: ChannelHandlerContext) {
    guard let continuation else { return }
    if case .dropped = continuation.yield(message) {
      continuation.finish()
      task?.cancel()
      context.close(promise: nil)
    }
  }

  func channelInactive(context: ChannelHandlerContext) {
    continuation?.finish()
    task?.cancel()
    context.fireChannelInactive()
  }

  func errorCaught(context: ChannelHandlerContext, error: any Error) {
    continuation?.finish()
    task?.cancel()
    context.close(promise: nil)
  }
}

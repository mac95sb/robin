import NIOCore
import NIOEmbedded
import NIOWebSocket
import Testing

@testable import RobinServer

@Test func websocketIngressClosesWhenItsBoundedBufferFills() async throws {
  let session = WebSocketSession { _, _ in
    try await Task.sleep(for: .seconds(10))
  }
  let channel = await NIOAsyncTestingChannel(handler: NIOWebSocketHandler(session: session))
  try await channel.connect(to: SocketAddress(ipAddress: "127.0.0.1", port: 8080))
  #expect(channel.isActive)

  for number in 0...NIOWebSocketHandler.maximumPendingMessages {
    try await channel.writeInbound(
      WebSocketFrame(fin: true, opcode: .text, data: ByteBuffer(string: "\(number)")))
  }
  #expect(!channel.isActive)
  _ = try await channel.finish(acceptAlreadyClosed: true)
}

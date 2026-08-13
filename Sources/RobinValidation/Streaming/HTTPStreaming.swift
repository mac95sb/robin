import NIOCore
import NIOHTTP1

/// Converts rendered HTML into deterministic byte-buffer chunks.
public enum StreamedHTML {
  /// Renders a node and divides its UTF-8 bytes into chunks no larger than `chunkSize`.
  ///
  /// - Precondition: `chunkSize` is greater than zero.
  public static func chunks(for node: RenderNode, chunkSize: Int = 64) -> [ByteBuffer] {
    precondition(chunkSize > 0)
    let bytes = Array(HTMLRenderer.render(node).utf8)
    return stride(from: 0, to: bytes.count, by: chunkSize).map { offset in
      ByteBuffer(bytes: bytes[offset..<min(offset + chunkSize, bytes.count)])
    }
  }
}

/// A validation-only NIO handler that routes request heads and streams rendered HTML.
public final class PrototypeHTTPHandler: ChannelInboundHandler, Sendable {
  public typealias InboundIn = HTTPServerRequestPart
  public typealias OutboundOut = HTTPServerResponsePart

  private let router: TypedRouter

  public init(router: TypedRouter) {
    self.router = router
  }

  public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    guard case .head(let request) = unwrapInboundIn(data) else { return }
    let node = router.match(method: request.method, path: request.uri)
    let status: HTTPResponseStatus = node == nil ? .notFound : .ok
    context.write(
      wrapOutboundOut(.head(HTTPResponseHead(version: request.version, status: status))),
      promise: nil)
    for chunk in StreamedHTML.chunks(for: node ?? .text("Not found"), chunkSize: 32) {
      context.write(wrapOutboundOut(.body(.byteBuffer(chunk))), promise: nil)
    }
    context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
  }
}

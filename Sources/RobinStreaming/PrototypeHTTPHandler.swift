import NIOCore
import NIOHTTP1
import RobinRendering
import RobinRouting

/// A validation-only NIO handler that routes request heads and streams rendered HTML.
///
/// The handler answers each request head with the matched route's rendered tree,
/// chunked into byte buffers of a fixed size. Unmatched paths receive `404
/// Not Found` with a plain-text body.
///
/// - Warning: This is a milestone prototype, not a production server: it ignores
///   request bodies and always responds inline on the channel's event loop.
public final class PrototypeHTTPHandler: ChannelInboundHandler, Sendable {
  public typealias InboundIn = HTTPServerRequestPart
  public typealias OutboundOut = HTTPServerResponsePart

  private let router: TypedRouter

  /// Creates a handler that serves the routes matched by `router`.
  ///
  /// - Parameter router: The typed router used to match incoming requests.
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

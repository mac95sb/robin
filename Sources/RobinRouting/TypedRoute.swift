import NIOHTTP1
import RobinRendering

/// An HTTP method and path pattern paired with a rendering handler.
public struct TypedRoute: Sendable {
  public let method: HTTPMethod
  public let segments: [RouteSegment]
  public let handler: @Sendable ([String: String]) -> RenderNode

  public init(
    method: HTTPMethod,
    segments: [RouteSegment],
    handler: @escaping @Sendable ([String: String]) -> RenderNode
  ) {
    self.method = method
    self.segments = segments
    self.handler = handler
  }
}

import RobinCore
import RobinRouting
import RobinServer

/// Serves the sample message endpoint.
struct MessageController: Controller {
  /// Registers `GET /api/v1/message`.
  @RoutesBuilder var body: RouteList {
    RouteGroup("message") { GET(use: message) }
  }

  /// Returns the starter message response.
  ///
  /// - Parameters:
  ///   - _: The route value; this endpoint has no path parameter.
  ///   - context: Metadata supplied by the server for the matching request.
  /// - Returns: A greeting message encoded as JSON.
  func message(_: Void, context: RequestContext) -> Message {
    Message(text: "Hello, world!")
  }
}

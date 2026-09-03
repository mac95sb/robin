import RobinHTML
import RobinRouting
import RobinServer

/// Sends normalized requests through Robin's transport-neutral responder.
public struct RouteTestClient: Sendable {
  private let responder: ApplicationResponder

  /// Creates a client for an application using persistent-transport capabilities.
  ///
  /// - Parameter application: The application to exercise without opening a listening socket.
  /// - Throws: Route-conflict, unsupported-route, or transport-capability diagnostics.
  public init<Application: App>(_ application: Application) throws {
    self.responder = try ApplicationResponder(
      application,
      transportCapabilities: .persistent
    )
  }

  /// Sends a request through the application's normal middleware and routing path.
  ///
  /// - Parameter request: The normalized request to execute.
  /// - Returns: The application response.
  public func response(to request: Request) async -> Response {
    await responder.respond(to: request)
  }
}

import RobinCore
import RobinHTML
import RobinServer

/// An API service with readiness and todo endpoints.
@main
struct API: App {
  /// Registers the service's controllers.
  @RoutesBuilder var routes: RouteList {
    HealthController()
    TodoController()
  }

  /// Starts the API server with the template's baseline security policy.
  static func main() async throws {
    try await RobinApplication.run(
      Self(),
      middleware: [
        .security(.init(requestsPerMinute: 120))
      ])
  }
}

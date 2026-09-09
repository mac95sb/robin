import RobinCore
import RobinHTML
import RobinServer
import RobinStyle
import RobinTheme

/// An API service with readiness and todo endpoints.
@main
struct API: App {
  var theme: any ApplicationTheme { Theme.robin }

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
      ]
    )
  }
}

import RobinCore
import RobinHTML
import RobinServer

@main
struct Site: App {
  @RoutesBuilder var routes: RouteList {
    RouteGroup("system") {
      HealthController()
    }
  }

  static func main() async throws { try await RobinApplication.run(Self()) }
}

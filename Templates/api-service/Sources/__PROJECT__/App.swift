import RobinCore
import RobinHTML
import RobinServer

@main
struct Site: App {
  private let todos = TodoService()

  @RoutesBuilder var routes: RouteList {
    RouteGroup("system") {
      HealthController()
    }
    RouteGroup("catalog") {
      TodoController(todos: todos)
    }
  }

  static func main() async throws {
    try await RobinApplication.run(
      Self(),
      middleware: [.security(.init(requestsPerMinute: 120))])
  }
}

import Foundation
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
      address: .init(
        host: "127.0.0.1", port: Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080),
      middleware: [.security(.init(requestsPerMinute: 120))])
  }
}

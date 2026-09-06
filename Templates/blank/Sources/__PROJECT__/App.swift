import Foundation
import RobinCore
import RobinHTML
import RobinServer

@main
struct Site: App {
  @PagesBuilder var pages: PageList { HomePage() }
  @RoutesBuilder var routes: RouteList { MessageController() }

  static func main() async throws {
    try await RobinApplication.run(
      Self(),
      address: .init(
        host: "127.0.0.1", port: Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080)
    )
  }
}

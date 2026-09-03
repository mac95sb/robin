import RobinCore
import RobinHTML
import RobinServer

@main
struct Site: App {
  var metadata: Metadata { Metadata(title: "__PROJECT__", language: "en") }

  @PagesBuilder var pages: PageList {
    ContentView()
    PageGroup("about") {
      AboutView()
    }
  }

  @RoutesBuilder var routes: RouteList {
    RouteGroup("system") {
      HealthController()
    }
  }

  static func main() async throws { try await RobinApplication.run(Self()) }
}

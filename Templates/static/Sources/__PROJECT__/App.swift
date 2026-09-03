import RobinBuild
import RobinCore
import RobinHTML

@main
struct Site: App {
  var metadata: Metadata { Metadata(title: "__PROJECT__", language: "en") }

  @PagesBuilder var pages: PageList {
    ContentView()
    PageGroup("about") {
      AboutView()
    }
  }

  static func main() throws { try RobinApplication.run(Self()) }
}

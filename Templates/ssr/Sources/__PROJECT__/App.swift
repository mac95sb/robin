import Foundation
import RobinContent
import RobinCore
import RobinHTML
import RobinServer

@main
struct Site: App {
  private let notes = NotesStore()

  var metadata: Metadata {
    Metadata(
      site: "__PROJECT__",
      separator: " — ",
      description: "A localized server-rendered Robin application.",
      image: .init(
        url: "https://example.com/social-card.png",
        alternativeText: "__PROJECT__ dashboard preview"),
      author: .init("__PROJECT__ Team"),
      publisher: .init("__PROJECT__"),
      structuredData: [
        .softwareApplication(.init(operatingSystem: "Any", category: "BusinessApplication"))
      ])
  }

  @PagesBuilder var pages: PageList {
    LocalizedPages(
      bundle: .module,
      baseURL: URL(string: "https://example.com")!
    ) {
      DashboardPage(notes: notes)
      AboutPage()
    }
  }

  @RoutesBuilder var routes: RouteList { AppController(notes: notes) }

  static func main() async throws { try await RobinApplication.run(Self()) }
}

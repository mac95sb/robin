import Foundation
import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle

/// A localized Markdown blog with static output.
@main
struct Site: App {
  var resourceBundle: Bundle? { .module }

  var theme: any ApplicationTheme { Theme.starter }

  var metadata: Metadata {
    Metadata(
      site: "__PROJECT__",
      separator: " — ",
      description: "A localized blog built with Robin.",
      image: .init(
        url: "/social-card.jpg",
        alternativeText: "__PROJECT__ journal preview",
        width: 1200,
        height: 630,
        mediaType: "image/jpeg"),
      author: .init("__PROJECT__ Team", url: "https://example.com/en/about"),
      publisher: .init("__PROJECT__"),
      icons: [.init(url: "/favicon.png", mediaType: "image/png")])
  }

  @PagesBuilder var pages: PageList {
    HomePage()
    PostPage()
    AboutPage()
  }

  static func main() throws {
    try RobinApplication.run(
      Self(),
      assets: [try SitePreferencesClientModule.asset()])
  }
}

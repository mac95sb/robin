import Foundation
import RobinBuild
import RobinCore
import RobinHTML
import RobinRuntime
import RobinStyle
import RobinTheme

struct Preferences: AppearancePreferences {
  var appearance: AppearanceButton.Preference = .system
}

/// A localized Markdown blog with static output.
@main
struct Site: App {
  static let preferences = Local("preferences", default: Preferences())

  var theme: any ApplicationTheme { Theme.robin }

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
        mediaType: "image/jpeg"
      ),
      author: .init("__PROJECT__ Team", url: "https://example.com/en/about"),
      publisher: .init("__PROJECT__"),
      icons: [.init(url: "/favicon.png", mediaType: "image/png")]
    )
  }

  @PagesBuilder var pages: PageList {
    HomePage()
    PostPage()
    AboutPage()
  }

  static func main() throws {
    try RobinApplication.run(Self())
  }
}

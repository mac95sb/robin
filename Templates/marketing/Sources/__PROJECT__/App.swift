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

/// A marketing site that demonstrates Robin’s component, styling, and browser APIs.
@main
struct Site: App {
  static let preferences = Local("preferences", default: Preferences())

  var theme: any ApplicationTheme { Theme.robin }
  var metadata: Metadata {
    Metadata(
      site: "Robin",
      separator: " — ",
      description: "Build thoughtful websites and full-stack applications in Swift.",
      image: .init(
        url: "/social-card.jpg",
        alternativeText: "Robin framework preview",
        width: 1200,
        height: 630,
        mediaType: "image/jpeg"
      ),
      icons: [.init(url: "/robin-logo.png", mediaType: "image/png")]
    )
  }
  var pages: some Pages { HomePage() }

  static func main() async throws {
    try RobinApplication.run(Self())
  }
}

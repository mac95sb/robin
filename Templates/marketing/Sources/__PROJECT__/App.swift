import Foundation
import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle

/// A marketing site that demonstrates Robin’s component, styling, and browser APIs.
@main
struct Site: App {
  var resourceBundle: Bundle? { .module }

  static let documentationURL =
    "https://mac95sb.github.io/robin/reference/RobinCore/documentation/robincore/"
  static var homeURL: String {
    CommandLine.arguments.contains("--github-pages") ? "https://mac95sb.github.io/robin/" : "/"
  }
  static let sourceURL = "https://github.com/mac95sb/robin"

  var theme: any ApplicationTheme { Theme.starter }
  var metadata: Metadata {
    Metadata(
      site: "Robin", separator: " — ",
      description: "Build thoughtful websites and full-stack applications in Swift.",
      image: .init(
        url: "/social-card.jpg",
        alternativeText: "Robin framework preview",
        width: 1200,
        height: 630,
        mediaType: "image/jpeg"),
      icons: [.init(url: "/robin-logo.png", mediaType: "image/png")])
  }
  var pages: some Pages { HomePage() }

  static func main() throws {
    let assets = [
      try SitePreferencesClientModule.asset(),
      try TabsClientModule(navigationID: "card-files", label: "Card source files").asset(),
      try TabsClientModule(navigationID: "counter-files", label: "Counter source files").asset(),
      try TabsClientModule(navigationID: "toggle-files", label: "Boolean source files").asset(),
      try TabsClientModule(navigationID: "text-files", label: "Text source files").asset(),
    ]
    if CommandLine.arguments.contains("--github-pages") {
      _ = try BuildPipeline.build(
        Self(),
        configuration: .init(
          assets: assets, cdnBaseURL: URL(string: "https://mac95sb.github.io/robin")!),
        in: OutputLayout(
          projectRoot: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)))
    } else {
      try RobinApplication.run(Self(), assets: assets)
    }
  }
}

import Foundation
import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle

@main
struct Site: App {
  static let documentationURL =
    "https://mac95sb.github.io/robin/reference/RobinCore/documentation/robincore"
  static let sourceURL = "https://github.com/mac95sb/robin"

  var theme: any ApplicationTheme { Theme.starter }
  var metadata: Metadata {
    Metadata(
      site: "Robin", separator: " — ",
      description: "Build thoughtful websites and full-stack applications in Swift.",
      icons: [.init(url: "/robin-logo.png", mediaType: "image/png")])
  }
  var pages: some Pages { HomePage() }

  static func main() throws {
    try RobinApplication.run(
      Self(),
      assets: [
        try BuildAsset(
          reference: "/robin-logo.png", path: "assets/robin-logo.png",
          bytes: Array(
            Data(contentsOf: Bundle.module.url(forResource: "robin-logo", withExtension: "png")!)),
          mediaType: "image/png"),
        try SitePreferencesClientModule.asset(),
        try TabsClientModule(navigationID: "card-files", label: "Card source files").asset(),
        try TabsClientModule(navigationID: "counter-files", label: "Counter source files").asset(),
        try TabsClientModule(navigationID: "toggle-files", label: "Boolean source files").asset(),
        try TabsClientModule(navigationID: "text-files", label: "Text source files").asset(),
      ])
  }
}

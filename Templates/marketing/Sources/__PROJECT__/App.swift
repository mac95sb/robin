import Foundation
import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle

@main
struct Site: App {
  static let documentationURL =
    "https://mac95sb.github.io/robin/docs/"
  static var homeURL: String {
    CommandLine.arguments.contains("--github-pages") ? "https://mac95sb.github.io/robin/" : "/"
  }
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
    let assets = [
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

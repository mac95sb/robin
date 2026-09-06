import Foundation
import RobinBuild
import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

@main
struct Site: App {
  var theme: any ApplicationTheme { Theme.starter }

  var metadata: Metadata {
    Metadata(
      site: "__PROJECT__",
      separator: " — ",
      description: "A localized blog built with Robin.",
      image: .init(
        url: "https://example.com/social-card.png",
        alternativeText: "__PROJECT__ product preview",
        width: 1200,
        height: 630,
        mediaType: "image/png"),
      author: .init("__PROJECT__ Team", url: "https://example.com/en/about"),
      publisher: .init("__PROJECT__"),
      icons: [.init(url: "/favicon.png", mediaType: "image/png")])
  }

  @PagesBuilder var pages: PageList {
    LocalizedPages(
      bundle: .module,
      baseURL: URL(string: "https://example.com")!
    ) {
      HomePage()
      PostPage()
      AboutPage()
    }
  }

  static func main() throws {
    try RobinApplication.run(
      Self(),
      assets: [
        try BuildAsset(
          reference: "/favicon.png", path: "assets/favicon.png",
          bytes: Array(
            try Data(contentsOf: Bundle.module.url(forResource: "favicon", withExtension: "png")!)),
          mediaType: "image/png"),
        try SitePreferencesClientModule.asset(),
      ])
  }
}

import Foundation
import RobinBuild
import RobinContent
import RobinCore
import RobinHTML

@main
struct Site: App {
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
      icons: [.init(url: "https://example.com/icon.svg", sizes: "any")],
      structuredData: [
        .softwareApplication(
          .init(operatingSystem: "Any", category: "BlogApplication"))
      ])
  }

  @PagesBuilder var pages: PageList {
    LocalizedPages(
      bundle: .module,
      baseURL: URL(string: "https://example.com")!
    ) {
      HomePage()
      AboutPage()
    }
  }

  static func main() throws { try RobinApplication.run(Self()) }
}

import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

struct AboutPage: Page {
  let path = "/about"

  var metadata: Metadata {
    Metadata(
      title: t("about"),
      description: t("aboutBody"),
      structuredData: [.article(.init(kind: .blogPosting))])
  }

  var body: ComponentContent {
    Main {
      Article {
        Heading { t("about") }
        Text { t("aboutBody") }
        Heading(.two) { t("ordinarySwift") }
        CodeBlock(
          "Heading { \"Hello, world!\" }",
          language: "swift",
          theme: .xcodeDefaultDark)
        Link(localizedPath("/")) { t("home") }
      }
    }
    .frame(maxWidth: 720)
    .margin(.lg)
  }
}

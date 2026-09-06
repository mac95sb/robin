import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

struct AboutPage: Page {
  let path = "/about"

  var metadata: Metadata {
    Metadata(
      title: t("about"),
      description: t("aboutBody"))
  }

  var body: ComponentContent {
    Stack {
      SiteHeader()
      Main {
        Article {
          Heading { t("about") }.starterTitle()
          Text { t("aboutBody") }
          Heading(.two) { t("ordinarySwift") }.starterTitle()
          CodeBlock(
            "Heading { \"Hello, world!\" }",
            language: "swift",
            theme: .xcode
          )
          .padding(.lg)
          .border(color: .border, width: 0, radius: .lg)
          Link(localizedPath("/")) { t("home") }.starterLink()
        }.starterSection()
      }
      .frame(maxWidth: 720)
      .grid(columns: 1, gap: .lg)
      SiteFooter()
    }.starterPage()
  }
}

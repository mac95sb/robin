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
      structuredData: [.article(.init())])
  }

  var body: ComponentContent {
    Main {
      Article {
        Heading { t("about") }
        Text { t("aboutBody") }
        Link(localizedPath("/")) { t("dashboard") }
      }
    }
    .frame(maxWidth: 720)
    .margin(.lg)
  }
}

import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

struct HomePage: Page {
  let path = "/"

  var metadata: Metadata {
    Metadata(title: t("home"), description: t("intro"))
  }

  var body: ComponentContent {
    Header {
      Navigation {
        Link(localizedPath("/")) { t("home") }
        Link(localizedPath("/about")) { t("about") }
      }
    }
    .padding(.md)

    Main {
      Heading { t("title") }
      Text { t("intro") }

      Section {
        Heading(.two) { t("benefits") }
        Stack {
          Text { t("typedComponents") }
          Text { t("localizedRoutes") }
          Text { t("structuredMetadata") }
        }
        .grid(columns: 1, gap: .md)
        .grid(columns: 3, gap: .lg, on: .md)
      }
    }
    .frame(maxWidth: 960)
    .margin(.lg)

    Footer { Text { t("footer") } }
      .padding(.md)
  }
}

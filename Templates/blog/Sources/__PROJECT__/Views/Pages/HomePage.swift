import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

struct HomePage: Page {
  let path = "/"
  private let welcome = MarkdownContentParser.parse(
    """
    ## A typed content pipeline

    Robin parses Markdown into semantic components, validates references, and emits static HTML.

    ![A European robin perched on a branch](https://images.example.com/robin.jpg)
    """,
    allowedEmbedHosts: []
  )

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
      Article { welcome }
    }
    .frame(maxWidth: 960)
    .margin(.lg)

    Footer { Text { t("footer") } }
      .padding(.md)
  }
}

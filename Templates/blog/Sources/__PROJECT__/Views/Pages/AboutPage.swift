import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

/// Explains the blog starter and its Swift-based composition.
struct AboutPage: Page {
  let path = "/about"

  var metadata: Metadata {
    Metadata(title: t("about"), description: t("aboutBody"))
  }

  var body: ComponentContent {
    BlogPage {
      SiteHeader()
      Main {
        BlogSection {
          Article {
            PageTitle { Heading { t("about") } }
            Text { t("aboutBody") }
            PageTitle { Heading(.two) { t("ordinarySwift") } }
            CodeBlock("Heading { \"Hello, world!\" }", language: "swift", theme: .xcode)
              .padding(.lg)
              .border(color: .border, width: 0, radius: .lg)
            SiteLabel { Link(localizedPath("/")) { t("home") } }
          }
        }
      }
      .frame(maxWidth: 720)
      .grid(columns: 1, gap: .lg)
      SiteFooter()
    }
  }
}

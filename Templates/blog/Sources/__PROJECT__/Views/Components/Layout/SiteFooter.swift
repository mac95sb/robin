import RobinContent
import RobinHTML
import RobinStyle

/// Renders the shared footer for every blog page.
struct SiteFooter: Component {
  var body: ComponentContent {
    Footer {
      SiteRule()
      Stack {
        SiteLabel { Text { "Built with Robin. Made to be your own." }.margin(.zero) }
        Navigation {
          SiteLabel {
            Link("https://git.maclong.dev/mac/robin/src/branch/main/Templates/blog") { "Source" }
          }
          SiteLabel { Link(localizedPath("/")) { "Back to journal" } }
        }
        .flex(wrap: .wrap, gap: .lg)
      }
      .flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
    }
    .grid(columns: 1, gap: .lg)
  }
}

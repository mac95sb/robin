import RobinContent
import RobinHTML
import RobinStyle

/// Renders the shared footer for every workspace page.
struct SiteFooter: Component {
  var body: ComponentContent {
    Footer {
      DashboardRule()
      Stack {
        DashboardLabel { Text { "Built with Robin. Made to be your own." }.margin(.zero) }
        Navigation {
          DashboardLabel {
            Link("https://github.com/mac95sb/robin/tree/main/Templates/dashboard") { "Source" }
          }
          DashboardLabel { Link(localizedPath("/")) { "Back to workspace" } }
        }
        .flex(wrap: .wrap, gap: .lg)
      }
      .flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
    }
    .grid(columns: 1, gap: .lg)
  }
}

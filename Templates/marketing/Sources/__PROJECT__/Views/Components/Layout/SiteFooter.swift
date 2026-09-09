import RobinHTML
import RobinStyle
import RobinTheme

/// Renders the marketing site footer.
struct SiteFooter: Component {
  let documentationURL: String

  var body: ComponentContent {
    Footer {
      Divider()
      Stack {
        RobinLabel { Text { "Built with Robin." }.margin(.zero) }
        Navigation {
          NavigationLink(documentationURL) { "Docs" }
        }
        .flex(wrap: .wrap, gap: .lg)
      }
      .flex(wrap: .wrap, justify: .spaceBetween, gap: .md)
    }
    .grid(columns: 1, gap: .lg)
  }
}

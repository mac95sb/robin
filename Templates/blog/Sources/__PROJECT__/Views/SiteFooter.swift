import RobinContent
import RobinHTML
import RobinStyle

struct SiteFooter: Component {
  var body: ComponentContent {
    Footer {
      Stack {}.starterRule()
      Stack {
        Text { "Built with Robin. Made to be your own." }.margin(.zero).starterLink()
        Navigation {
          Link("https://github.com/mac95sb/robin/tree/main/Templates/blog") { "Source" }
            .starterLink()
          Link(localizedPath("/")) { "Back to journal" }.starterLink()
        }.flex(wrap: .wrap, gap: .lg)
      }.flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
    }.grid(columns: 1, gap: .lg)
  }
}

import RobinHTML
import RobinStyle

/// Styles section and page headings.
struct PageTitle: Component {
  private let content: ComponentContent

  /// Creates a page title from the supplied heading.
  init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  var body: ComponentContent {
    content.margin(.zero).font(.title, lineHeight: 36, letterSpacing: -1)
  }
}

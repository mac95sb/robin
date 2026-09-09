import RobinHTML
import RobinStyle
import RobinTheme

/// Styles section and page headings.
struct PageTitle: Component {
  private let content: ComponentContent

  /// Creates a page title from the supplied heading.
  init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  var body: ComponentContent {
    RobinTitle { content }
  }
}

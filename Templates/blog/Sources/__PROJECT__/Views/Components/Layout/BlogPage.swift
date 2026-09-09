import RobinHTML
import RobinStyle
import RobinTheme

/// Applies the shared page frame for the blog.
struct BlogPage: Component {
  private let content: ComponentContent

  /// Creates a page frame containing the supplied page content.
  init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  var body: ComponentContent {
    RobinPage { content }
  }
}

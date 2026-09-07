import RobinHTML
import RobinStyle

/// Groups related blog content with the standard vertical rhythm.
struct BlogSection: Component {
  private let content: ComponentContent

  /// Creates a grouped section from the supplied content.
  init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  var body: ComponentContent {
    content.grid(columns: 1, gap: .md)
  }
}

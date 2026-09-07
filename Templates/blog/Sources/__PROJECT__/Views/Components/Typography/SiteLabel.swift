import RobinHTML
import RobinStyle

/// Styles supporting text and low-emphasis links.
struct SiteLabel: Component {
  private let content: ComponentContent

  /// Creates a styled label from the supplied content.
  init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  var body: ComponentContent {
    content.font(.label, color: .muted, decoration: TextDecoration.none)
      .font(.label, color: .muted, on: .dark)
  }
}

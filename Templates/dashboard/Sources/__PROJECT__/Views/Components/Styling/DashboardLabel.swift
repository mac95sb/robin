import RobinHTML
import RobinStyle

/// Styles subdued dashboard labels and links.
struct DashboardLabel: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.font(.label, color: .muted, decoration: TextDecoration.none)
      .font(.label, color: .muted, on: .dark)
  }
}

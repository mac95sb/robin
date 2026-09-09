import RobinHTML
import RobinStyle
import RobinTheme

/// Styles subdued dashboard labels and links.
struct DashboardLabel: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    RobinLabel { content }
  }
}

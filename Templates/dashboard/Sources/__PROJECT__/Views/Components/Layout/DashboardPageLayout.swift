import RobinHTML
import RobinStyle
import RobinTheme

/// Applies the shared workspace page layout.
struct DashboardPageLayout: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    RobinPage { content }
  }
}

import RobinHTML
import RobinStyle
import RobinTheme

/// Styles a workspace section title.
struct DashboardTitle: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    RobinTitle { content }
  }
}

import RobinHTML
import RobinStyle

/// Styles a workspace section title.
struct DashboardTitle: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.margin(.zero).font(.title, lineHeight: 36, letterSpacing: -1)
  }
}

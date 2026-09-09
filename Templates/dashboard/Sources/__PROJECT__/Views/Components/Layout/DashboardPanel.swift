import RobinHTML
import RobinStyle
import RobinTheme

/// Groups related workspace content on an elevated surface.
struct DashboardPanel: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    RobinPanel { content.padding(.lg).padding(.xl, on: .md) }
  }
}

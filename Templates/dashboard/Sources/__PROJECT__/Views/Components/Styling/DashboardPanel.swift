import RobinHTML
import RobinStyle

/// Groups related workspace content on an elevated surface.
struct DashboardPanel: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.padding(.lg).padding(.xl, on: .md)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, width: 0, radius: .xl)
  }
}

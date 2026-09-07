import RobinHTML
import RobinStyle

/// Groups related marketing content on an elevated surface.
struct MarketingPanel: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, width: 0, radius: .xl)
  }
}

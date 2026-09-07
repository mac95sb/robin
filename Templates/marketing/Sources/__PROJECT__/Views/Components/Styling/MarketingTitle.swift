import RobinHTML
import RobinStyle

/// Styles a marketing section title.
struct MarketingTitle: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.margin(.zero).font(.title, lineHeight: 36, letterSpacing: -1)
  }
}

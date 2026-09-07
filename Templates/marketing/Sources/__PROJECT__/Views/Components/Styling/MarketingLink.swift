import RobinHTML
import RobinStyle

/// Styles a marketing navigation or footer link.
struct MarketingLink: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    MarketingLabel { content }
      .font(.label, color: .accent, on: .hover || .focus)
      .font(.label, color: .accent, on: .dark && (.hover || .focus))
  }
}

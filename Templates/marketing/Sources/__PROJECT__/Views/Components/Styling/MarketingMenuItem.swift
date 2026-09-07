import RobinHTML
import RobinStyle

/// Styles one interactive item in a menu or picker.
struct MarketingMenuItem: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.flex(align: .center, gap: .sm).padding(.sm)
      .font(.label, color: .foreground, decoration: TextDecoration.none)
      .font(.label, color: .foreground, on: .dark)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, width: 0, radius: .sm)
      .font(.label, color: .accent, on: .pressed)
      .font(.label, color: .accent, on: .dark && .pressed)
      .background(color: .cardHover, on: .hover || .focus)
      .background(color: .cardHover, on: .dark && (.hover || .focus))
  }
}

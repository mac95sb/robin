import RobinHTML
import RobinStyle

/// Styles a prominent or secondary marketing action.
struct MarketingAction: Component {
  let primary: Bool
  private let content: ComponentContent

  init(primary: Bool = true, @ViewBuilder content: () -> ComponentContent) {
    self.primary = primary
    self.content = content()
  }

  var body: ComponentContent {
    content.flex(justify: .center, align: .center).frame(width: 160).padding(.md)
      .font(.emphasis, color: primary ? .surface : .foreground, decoration: TextDecoration.none)
      .font(.emphasis, color: primary ? .background : .foreground, on: .dark)
      .background(color: primary ? .accent : .surface)
      .background(color: primary ? .accent : .surface, on: .dark)
      .border(color: .accent, width: 0, radius: .md)
      .background(color: primary ? .accentHover : .cardHover, on: .hover || .focus)
      .background(color: primary ? .accentHover : .cardHover, on: .dark && (.hover || .focus))
  }
}

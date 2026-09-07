import RobinHTML
import RobinStyle

/// Styles a compact square picker trigger.
struct MarketingPicker: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.flex(justify: .center, align: .center).frame(width: 44, height: 44).padding(.zero)
      .font(.label, color: .foreground).font(.label, color: .foreground, on: .dark)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
      .background(color: .cardHover, on: .hover || .focus)
      .background(color: .cardHover, on: .dark && (.hover || .focus))
  }
}

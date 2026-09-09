import RobinHTML
import RobinStyle

/// Styles the square trigger used to open a site menu.
struct MenuTrigger: Component {
  private let content: ComponentContent

  /// Creates a menu trigger from the supplied button.
  init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  var body: ComponentContent {
    content.flex(justify: .center, align: .center)
      .frame(width: 44, height: 44).padding(.zero)
      .font(.label, color: .foreground)
      .font(color: .foreground, on: .dark)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
  }
}

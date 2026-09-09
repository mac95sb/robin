import RobinHTML
import RobinStyle

/// Styles an action inside a navigation popover.
struct MenuItem: Component {
  private let content: ComponentContent

  /// Creates a menu item from the supplied link or control.
  init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  var body: ComponentContent {
    content.flex(align: .center, gap: .sm).padding(.sm)
      .font(.label, color: .foreground, decoration: TextDecoration.none)
      .font(color: .foreground, on: .dark)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, width: 0, radius: .sm)
      .font(color: .accent, on: .pressed)
      .font(color: .accent, on: .dark && .pressed)
      .background(color: .background, on: .hover || .focus)
      .background(color: .background, on: .dark && (.hover || .focus))
  }
}

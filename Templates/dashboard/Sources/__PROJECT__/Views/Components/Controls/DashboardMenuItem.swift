import RobinHTML
import RobinStyle

/// Styles one interactive menu item.
struct DashboardMenuItem: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

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

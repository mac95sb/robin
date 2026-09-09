import RobinHTML
import RobinStyle

/// A styled menu link.
struct MenuLink: Component {
  private let destination: String
  private let content: ComponentContent

  /// Creates a menu link to a destination.
  init(_ destination: String, @ViewBuilder content: () -> ComponentContent) {
    self.destination = destination
    self.content = content()
  }

  var body: ComponentContent {
    Link(destination) { content }
      .flex(align: .center, gap: .sm).padding(.sm)
      .font(.label, color: .foreground, decoration: TextDecoration.none)
      .font(color: .foreground, on: .dark)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, width: 0, radius: .sm)
      .font(color: .accent, on: .pressed)
      .font(color: .accent, on: .dark && .pressed)
      .background(color: .cardHover, on: .hover || .focus)
      .background(color: .cardHover, on: .dark && (.hover || .focus))
  }
}

import RobinHTML
import RobinStyle

/// A compact square button that opens or closes a native popover.
struct MenuTrigger: Component {
  private let accessibilityLabel: String
  private let content: ComponentContent

  /// Creates a menu trigger button.
  init(
    accessibilityLabel: String,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.accessibilityLabel = accessibilityLabel
    self.content = content()
  }

  var body: ComponentContent {
    Button(accessibilityLabel: accessibilityLabel) { content }
      .flex(justify: .center, align: .center).frame(width: 44, height: 44).padding(.zero)
      .font(.label, color: .foreground).font(color: .foreground, on: .dark)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
      .background(color: .cardHover, on: .hover || .focus)
      .background(color: .cardHover, on: .dark && (.hover || .focus))
  }
}

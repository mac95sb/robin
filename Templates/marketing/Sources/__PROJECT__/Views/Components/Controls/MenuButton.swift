import RobinHTML
import RobinRuntime
import RobinStyle

/// A styled menu button.
struct MenuButton: Component {
  private let accessibilityLabel: String?
  private let command: PopoverCommand?
  private let action: StateAction?
  private let content: ComponentContent

  /// Creates a menu button with optional native and state actions.
  init(
    accessibilityLabel: String? = nil,
    command: PopoverCommand? = nil,
    action: StateAction? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.accessibilityLabel = accessibilityLabel
    self.command = command
    self.action = action
    self.content = content()
  }

  var body: ComponentContent {
    Button(accessibilityLabel: accessibilityLabel, command: command, action: action) { content }
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

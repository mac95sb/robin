import RobinHTML
import RobinStyle

/// A styled native popover.
struct MenuPopover: Component {
  private let content: ComponentContent

  /// Creates styled popover content.
  init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  var body: ComponentContent {
    Stack { content }
      .popoverPosition(gap: 8).padding(.sm).frame(minWidth: 144)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
  }
}

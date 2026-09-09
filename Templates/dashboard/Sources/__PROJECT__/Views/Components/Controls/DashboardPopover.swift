import RobinHTML
import RobinStyle

/// Styles a popover surface used by workspace controls.
struct DashboardPopover: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.popoverPosition(gap: 8).padding(.sm).frame(minWidth: 144)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
  }
}

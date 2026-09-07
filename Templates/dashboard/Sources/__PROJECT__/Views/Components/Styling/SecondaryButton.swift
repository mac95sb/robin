import RobinHTML
import RobinStyle

/// Styles a secondary workspace action.
struct SecondaryButton: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.font(.label, color: .foreground, lineHeight: 20).font(
      .label, color: .foreground, lineHeight: 20, on: .dark
    )
    .padding(.sm).background(color: .surface).background(color: .surface, on: .dark)
    .border(color: .border, radius: .sm).border(color: .border, radius: .sm, on: .dark)
    .border(color: .accent, radius: .sm, on: .focus)
  }
}

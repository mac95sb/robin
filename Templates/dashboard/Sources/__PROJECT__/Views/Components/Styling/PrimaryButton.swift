import RobinHTML
import RobinStyle

/// Styles a primary workspace action.
struct PrimaryButton: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.font(.label, color: .onAccent, lineHeight: 20).font(
      .label, color: .onAccent, lineHeight: 20, on: .dark
    )
    .padding(.sm).background(color: .accent).background(color: .accent, on: .dark)
    .border(color: .accent, radius: .sm).border(color: .accent, radius: .sm, on: .dark)
    .border(color: .foreground, radius: .sm, on: .focus)
  }
}

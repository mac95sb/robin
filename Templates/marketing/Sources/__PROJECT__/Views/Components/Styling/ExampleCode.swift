import RobinHTML
import RobinStyle

/// Styles generated source code in a marketing example.
struct ExampleCode: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    content.margin(.zero).padding(.lg).border(color: .border, width: 0, radius: .lg).frame(
      minWidth: 0)
  }
}

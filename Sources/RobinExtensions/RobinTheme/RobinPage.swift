import RobinHTML
import RobinStyle

/// Applies Robin's responsive site frame to page content.
public struct RobinPage: Component {
  private let content: ComponentContent

  /// Creates a page frame containing the supplied content.
  public init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  /// The framed page content.
  public var body: ComponentContent {
    Stack {
      content.grid(columns: 1, gap: .xxl).frame(maxWidth: 1080).flexItem(grow: 1)
    }
    .flex(justify: .center)
    .padding(.lg).padding(.xxl, on: .md)
    .font(.body, color: .foreground, lineHeight: 26)
    .font(.body, color: .foreground, lineHeight: 26, on: .dark)
    .background(color: .background).background(color: .background, on: .dark)
  }
}

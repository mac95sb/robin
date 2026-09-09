import RobinHTML
import RobinStyle

/// Styles supporting text and low-emphasis links.
public struct RobinLabel: Component {
  private let content: ComponentContent

  /// Creates a label from the supplied content.
  public init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  /// The styled label content.
  public var body: ComponentContent {
    content.font(.label, color: .muted, decoration: TextDecoration.none)
      .font(.label, color: .muted, on: .dark)
  }
}

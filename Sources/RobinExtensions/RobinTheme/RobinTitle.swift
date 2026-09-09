import RobinHTML
import RobinStyle

/// Styles a section or page heading.
public struct RobinTitle: Component {
  private let content: ComponentContent

  /// Creates a title from the supplied heading content.
  public init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  /// The styled title content.
  public var body: ComponentContent {
    content.margin(.zero).font(.title, lineHeight: 36, letterSpacing: -1)
  }
}

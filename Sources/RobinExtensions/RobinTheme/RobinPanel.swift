import RobinHTML
import RobinStyle

/// Groups related content on a bordered surface.
public struct RobinPanel: Component {
  private let content: ComponentContent

  /// Creates a panel containing the supplied content.
  public init(@ViewBuilder content: () -> ComponentContent) {
    self.content = content()
  }

  /// The styled panel content.
  public var body: ComponentContent {
    content.background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, width: 0, radius: .xl)
  }
}

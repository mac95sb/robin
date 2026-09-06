/// A native auto popover, dismissed by Escape or an outside click.
public struct Popover: Component {
  private let id: String
  private let content: ComponentContent

  /// Creates a popover targeted by a button's standard command.
  /// - Parameters:
  ///   - id: The unique target identifier.
  ///   - content: The popover's content.
  public init(id: String, @ViewBuilder content: () -> ComponentContent) {
    self.id = id
    self.content = content()
  }

  /// The native popover element.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(kind: .div, attributes: [.identifier(id), .popover], children: content.nodes))
    )
  }
}

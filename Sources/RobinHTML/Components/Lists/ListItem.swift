/// A single entry within a ``List``.
///
/// `ListItem` lowers to `<li>`.
public struct ListItem: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a list item containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the item's content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved list item and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .li,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}

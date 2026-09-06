/// A single entry within a ``List``.
///
/// `ListItem` lowers to `<li>`.
public struct ListItem: Component {
  private let identifier: String?
  private let title: String?
  private let content: ComponentContent

  /// Creates a list item containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - title: Optional supplementary text shown as a native hover tooltip.
  ///   - content: A view builder that creates the item's content.
  public init(
    id: String? = nil,
    title: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.title = title
    self.content = content()
  }

  /// The resolved list item and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .li,
          attributes: (identifier.map { [.identifier($0)] } ?? [])
            + (title.map { [.title($0)] } ?? []),
          children: content.nodes
        )
      )
    )
  }
}

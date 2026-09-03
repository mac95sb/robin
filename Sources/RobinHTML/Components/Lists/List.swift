/// An ordered or unordered list of items.
///
/// `List` lowers to `<ol>` or `<ul>` depending on `ordered`. Its content is typically built from
/// ``ListItem`` values, one per entry.
public struct List: Component {
  private let ordered: Bool
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a list containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - ordered: Whether the list's items have a meaningful sequence. The default is `false`.
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the list's items.
  public init(
    ordered: Bool = false,
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.ordered = ordered
    self.identifier = id
    self.content = content()
  }

  /// The resolved list and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: ordered ? .ol : .ul,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}

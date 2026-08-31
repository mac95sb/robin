@_spi(Rendering) import RobinCore

/// A data cell within a ``TableRow``.
///
/// `TableCell` lowers to `<td>`.
public struct TableCell: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a table cell containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the cell's content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved table cell and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .td,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: Text.phrasingContent(content).nodes
        )
      )
    )
  }
}

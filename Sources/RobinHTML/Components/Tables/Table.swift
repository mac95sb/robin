/// A table of tabular data.
///
/// `Table` lowers to `<table>`. Its content is typically built from ``TableRow`` values.
public struct Table: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a table containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the table's rows.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved table and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .table,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}

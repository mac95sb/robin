/// A table of tabular data.
///
/// `Table` lowers to `<table>`. Its content is typically built from ``TableRow`` values.
///
/// HTML reference: [MDN: table](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/table).
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
    .element(.table, id: identifier, children: content.nodes)
  }
}

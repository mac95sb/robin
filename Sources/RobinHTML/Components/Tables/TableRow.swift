/// A single row within a ``Table``.
///
/// `TableRow` lowers to `<tr>`. Its content is typically built from ``TableHeaderCell`` and
/// ``TableCell`` values.
public struct TableRow: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a table row containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the row's cells.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved table row and its child content.
  public var body: ComponentContent {
    .element(.tr, id: identifier, children: content.nodes)
  }
}

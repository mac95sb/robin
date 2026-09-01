@_spi(Rendering) import RobinCore

/// A header cell within a ``TableRow``.
///
/// `TableHeaderCell` lowers to `<th>`.
public struct TableHeaderCell: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a table header cell containing the components produced by a view builder.
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

  /// The resolved table header cell and its child content.
  public var body: ComponentContent {
    .element(.th, id: identifier, children: Text.phrasingContent(content).nodes)
  }
}

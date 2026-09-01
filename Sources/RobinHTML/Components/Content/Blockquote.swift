/// An extended quotation from another source.
///
/// `Blockquote` lowers to `<blockquote>`.
public struct Blockquote: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a blockquote containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the quotation's content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved blockquote and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .blockquote,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}

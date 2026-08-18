/// A block of preformatted code.
///
/// `CodeBlock` lowers to `<pre><code>...</code></pre>`. Text content is rendered verbatim,
/// preserving whitespace and line breaks.
public struct CodeBlock: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a code block containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the code block's content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved code block wrapping its content in a nested code element.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .pre,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: [.element(RenderElement(kind: .code, children: content.nodes))]
        )
      )
    )
  }
}

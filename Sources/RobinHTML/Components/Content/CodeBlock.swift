/// A block of preformatted code.
///
/// `CodeBlock` lowers to `<pre><code>...</code></pre>`. Text content is rendered verbatim,
/// preserving whitespace and line breaks.
public struct CodeBlock: Component {
  private let identifier: String?
  private let language: String?
  private let theme: SyntaxHighlightTheme?
  private let content: ComponentContent

  /// Creates a code block containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the code block's content.
  public init(
    id: String? = nil,
    language: String? = nil,
    theme: SyntaxHighlightTheme? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.language = language
    self.theme = theme
    self.content = content()
  }

  /// The resolved code block wrapping its content in a nested code element.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .pre,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: [
            .element(
              RenderElement(kind: .code, attributes: codeAttributes, children: content.nodes))
          ]
        )
      )
    )
  }

  private var codeAttributes: [RenderElement.Attribute] {
    [
      language.map(RenderElement.Attribute.syntaxLanguage),
      theme.map(RenderElement.Attribute.syntaxTheme),
    ].compactMap { $0 }
  }
}

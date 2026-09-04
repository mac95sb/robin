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
  ///   - language: An optional syntax-language identifier.
  ///   - theme: An optional curated syntax-highlighting theme.
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

  /// Creates a code block highlighted by Robin's shared native highlighter.
  public init(
    _ source: String,
    id: String? = nil,
    language: String? = nil,
    theme: SyntaxHighlightTheme? = nil
  ) {
    self.init(
      SyntaxHighlighter.highlight(source, language: language), id: id, language: language,
      theme: theme)
  }

  /// Creates a code block from semantic runs produced earlier in a render pipeline.
  public init(
    _ highlights: [SyntaxHighlighter.Run],
    id: String? = nil,
    language: String? = nil,
    theme: SyntaxHighlightTheme? = nil
  ) {
    self.identifier = id
    self.language = language
    self.theme = theme
    self.content = .init(
      nodes: highlights.flatMap { run in
        if let kind = run.kind { return CaseHighlight(kind) { run.text }.body.nodes }
        return [.text(run.text)]
      })
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

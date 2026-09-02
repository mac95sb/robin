/// A semantically highlighted region inside a ``CodeBlock``.
///
/// Unhighlighted source remains ordinary text. A highlighter groups adjacent source with the same
/// role into one `CaseHighlight`, so the rendered output does not wrap every lexical token in a
/// `<span>`.
public struct CaseHighlight: Component {
  /// A theme-independent source-code role interpreted by the selected syntax theme.
  public enum Kind: String, Equatable, Sendable {
    /// An annotation or declaration attribute.
    case attribute
    /// A source-code comment.
    case comment
    /// A function or method name.
    case function
    /// A language keyword.
    case keyword
    /// A general literal value.
    case literal
    /// A numeric literal.
    case number
    /// A property or field name.
    case property
    /// A string literal.
    case string
    /// A type name.
    case type
  }

  private let kind: Kind
  private let content: ComponentContent

  /// Creates one highlighted source region.
  ///
  /// - Parameters:
  ///   - kind: The semantic source-code role.
  ///   - content: A view builder that creates the highlighted source.
  public init(_ kind: Kind, @ViewBuilder content: () -> ComponentContent) {
    self.kind = kind
    self.content = content()
  }

  /// The resolved inline highlight and its source content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .span,
          attributes: [.syntaxHighlight(kind)],
          children: content.nodes
        )
      )
    )
  }
}

/// A semantically highlighted region inside a ``CodeBlock``.
///
/// Unhighlighted source remains ordinary text. A highlighter groups adjacent source with the same
/// role into one `CaseHighlight`, so the rendered output does not wrap every lexical token in a
/// `<span>`.
public struct CaseHighlight: Component {
  /// A theme-independent source-code role interpreted by the selected syntax theme.
  public enum Kind: String, Equatable, Sendable {
    case attribute
    case comment
    case function
    case keyword
    case literal
    case number
    case property
    case string
    case type
  }

  private let kind: Kind
  private let content: ComponentContent

  /// Creates one highlighted source region.
  public init(_ kind: Kind, @ViewBuilder content: () -> ComponentContent) {
    self.kind = kind
    self.content = content()
  }

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

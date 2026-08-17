/// A node in Robin's render intermediate representation (IR).
///
/// Render trees are the framework-independent description of a view: they are
/// produced by ``ValidationComponent`` bodies, checked by ``RenderValidator``,
/// and serialized to HTML by ``HTMLRenderer``.
public indirect enum RenderNode: Equatable, Sendable {
  /// An HTML element with attributes and children.
  case element(ElementNode)

  /// A literal text run, HTML-escaped at render time.
  case text(String)

  /// An ordered group of nodes with no wrapping element.
  case fragment([RenderNode])

  /// A sandboxed external embed.
  case embed(EmbedNode)
}

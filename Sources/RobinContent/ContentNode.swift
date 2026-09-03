/// A typed block-level node parsed from a content document.
public enum ContentNode: Equatable, Sendable {
  /// A section heading with its outline level (1–6).
  case heading(level: Int, text: String)

  /// A paragraph of body text.
  case paragraph(String)

  /// A fenced code block with an optional language tag.
  case code(language: String?, source: String)

  /// A table: the first row is the header, the rest are body rows.
  case table([[String]])

  /// A footnote definition, referenced by `id` from body text.
  case footnote(id: String, text: String)

  /// A highlighted callout (note, tip, warning, or important).
  case admonition(AdmonitionNode)

  /// A typed external embed.
  case embed(source: String, title: String)
}

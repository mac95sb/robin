/// Typed phrasing content parsed from Markdown.
public indirect enum ContentInline: Equatable, Sendable {
  /// Ordinary text.
  case text(String)
  /// Stress emphasis.
  case emphasis([ContentInline])
  /// Strong importance.
  case strong([ContentInline])
  /// Inline source code.
  case code(String)
  /// A hyperlink and its visible content.
  case link(destination: String, content: [ContentInline])
  /// An image and its textual alternative.
  case image(source: String, alternativeText: String)
  /// A native link to a footnote definition.
  case footnoteReference(id: String, occurrence: Int)
}

extension Array where Element == ContentInline {
  package var plainText: String {
    map { inline in
      switch inline {
      case .text(let text), .code(let text): text
      case .emphasis(let content), .strong(let content), .link(_, let content): content.plainText
      case .image(_, let alternativeText): alternativeText
      case .footnoteReference(let id, _): "[\(id)]"
      }
    }.joined()
  }
}

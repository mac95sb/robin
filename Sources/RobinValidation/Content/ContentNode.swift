/// A typed block-level node parsed from a content document.
public enum ContentNode: Equatable, Sendable {
  case heading(level: Int, text: String)
  case paragraph(String)
  case code(language: String?, source: String)
  case table([[String]])
  case footnote(id: String, text: String)
  case embed(EmbedNode)
}

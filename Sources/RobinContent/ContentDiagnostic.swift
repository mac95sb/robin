/// A diagnostic emitted while converting source content into typed nodes.
public enum ContentDiagnostic: Error, Equatable, Sendable {
  /// Raw HTML appeared where only typed content is accepted.
  case rawHTMLRejected
  /// An embed directive contains the invalid source description.
  case invalidEmbed(String)
  /// The parser encountered a Markdown node it cannot represent.
  case unsupportedNode(String)
}

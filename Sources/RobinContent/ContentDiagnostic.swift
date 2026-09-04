/// A diagnostic emitted while converting source content into typed nodes.
public enum ContentDiagnostic: Error, Equatable, Sendable {
  /// Front matter contained an invalid field or value.
  case invalidFrontMatter(String)
  /// Raw HTML appeared where only typed content is accepted.
  case rawHTMLRejected
  /// An embed directive contains the invalid source description.
  case invalidEmbed(String)
  /// A local link does not match a generated route.
  case brokenLink(String)
  /// A local image does not match a generated asset.
  case missingAsset(String)
  /// A reference cannot be resolved safely.
  case invalidReference(String)
  /// A footnote reference has no matching definition.
  case missingFootnote(String)
  /// A footnote identifier is defined more than once.
  case duplicateFootnote(String)
  /// The parser encountered a Markdown node it cannot represent.
  case unsupportedNode(String)
}

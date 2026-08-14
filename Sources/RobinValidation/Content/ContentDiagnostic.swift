/// A diagnostic emitted while converting source content into typed nodes.
public enum ContentDiagnostic: Error, Equatable, Sendable {
  case rawHTMLRejected
  case invalidEmbed(String)
  case unsupportedNode(String)
}

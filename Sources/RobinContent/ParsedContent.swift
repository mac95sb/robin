/// The typed nodes and nonfatal diagnostics produced by parsing content.
public struct ParsedContent: Equatable, Sendable {
  /// The successfully converted content nodes in source order.
  public let nodes: [ContentNode]
  /// Nonfatal problems encountered while parsing the document.
  public let diagnostics: [ContentDiagnostic]
}

/// The typed nodes and nonfatal diagnostics produced by parsing content.
public struct ParsedContent: Equatable, Sendable {
  public let nodes: [ContentNode]
  public let diagnostics: [ContentDiagnostic]
}

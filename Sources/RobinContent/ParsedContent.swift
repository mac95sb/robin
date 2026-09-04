/// The typed nodes and nonfatal diagnostics produced by parsing content.
public struct ParsedContent: Equatable, Sendable {
  /// Typed front matter parsed before the Markdown body.
  public let frontMatter: ContentFrontMatter
  /// The successfully converted content nodes in source order.
  public let nodes: [ContentNode]
  /// Links and assets referenced by the source document.
  public let references: [ContentReference]
  /// Nonfatal problems encountered while parsing the document.
  public let diagnostics: [ContentDiagnostic]

  /// Anchored headings in document order.
  public var tableOfContents: [TableOfContentsEntry] {
    nodes.compactMap { node in
      guard case .heading(let level, let id, let content) = node else { return nil }
      return TableOfContentsEntry(level: level, id: id, title: content.plainText)
    }
  }

  /// Creates a parsed content result.
  public init(
    frontMatter: ContentFrontMatter = .init(),
    nodes: [ContentNode],
    references: [ContentReference] = [],
    diagnostics: [ContentDiagnostic]
  ) {
    self.frontMatter = frontMatter
    self.nodes = nodes
    self.references = references
    self.diagnostics = diagnostics
  }
}

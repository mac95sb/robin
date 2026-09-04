import RobinContent

/// A plugin that transforms parsed Markdown content.
public protocol MarkdownPlugin: Plugin {
  /// Transforms a parsed document during the content pipeline.
  ///
  /// - Parameter content: Content produced by the preceding Markdown stage.
  /// - Returns: Content for the next stage.
  /// - Throws: An error raised while transforming the document.
  func transform(_ content: ParsedContent) throws -> ParsedContent
}

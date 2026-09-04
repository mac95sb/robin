/// One identified document in a content collection.
public struct ContentDocument: Equatable, Sendable {
  /// Stable collection identity.
  public let id: String
  /// Parsed front matter.
  public let frontMatter: ContentFrontMatter
  /// Parsed body content.
  public let content: ParsedContent

  /// Creates a collection document.
  public init(id: String, frontMatter: ContentFrontMatter, content: ParsedContent) {
    precondition(!id.isEmpty)
    self.id = id
    self.frontMatter = frontMatter
    self.content = content
  }
}

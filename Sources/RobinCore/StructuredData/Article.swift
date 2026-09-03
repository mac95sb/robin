import Foundation

extension StructuredData {
  /// Schema-specific article facts.
  public struct Article: Equatable, Sendable {
    /// The Schema.org article type.
    public let kind: Kind
    /// The article's author.
    public let author: Person
    /// When the article was first published.
    public let datePublished: Date
    /// When the article was most recently modified.
    public let dateModified: Date?

    /// Creates article facts.
    public init(
      kind: Kind = .article,
      author: Person,
      datePublished: Date,
      dateModified: Date? = nil
    ) {
      self.kind = kind
      self.author = author
      self.datePublished = datePublished
      self.dateModified = dateModified
    }

    /// A supported Schema.org article type.
    public enum Kind: String, Equatable, Sendable {
      /// A general article.
      case article = "Article"
      /// A blog post.
      case blogPosting = "BlogPosting"
      /// A news article.
      case newsArticle = "NewsArticle"
    }
  }
}

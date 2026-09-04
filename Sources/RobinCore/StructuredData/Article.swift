import Foundation

extension StructuredData {
  /// Schema-specific article facts.
  public struct Article: Equatable, Sendable {
    /// The Schema.org article type.
    public let kind: Kind
    /// Creates article facts.
    public init(kind: Kind = .article) { self.kind = kind }

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

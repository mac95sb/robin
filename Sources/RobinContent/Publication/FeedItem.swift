import Foundation

/// One entry in an RSS or Atom feed.
public struct FeedItem: Equatable, Sendable {
  /// Entry title.
  public let title: String
  /// Absolute canonical URL.
  public let url: String
  /// Optional summary.
  public let summary: String?
  /// Publication date.
  public let publishedAt: Date
  /// Optional modification date.
  public let modifiedAt: Date?

  /// Creates a feed entry.
  public init(
    title: String,
    url: String,
    summary: String? = nil,
    publishedAt: Date,
    modifiedAt: Date? = nil
  ) {
    precondition(!title.isEmpty && !url.isEmpty)
    self.title = title
    self.url = url
    self.summary = summary
    self.publishedAt = publishedAt
    self.modifiedAt = modifiedAt
  }
}

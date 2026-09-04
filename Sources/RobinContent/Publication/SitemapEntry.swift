import Foundation

/// One canonical URL and its localized equivalents in a sitemap.
public struct SitemapEntry: Equatable, Sendable {
  /// Absolute canonical URL.
  public let url: String
  /// Last content modification time.
  public let modifiedAt: Date?
  /// Alternate language tags mapped to locale-specific canonical URLs.
  public let alternates: [String: String]

  /// Creates a sitemap entry.
  public init(url: String, modifiedAt: Date? = nil, alternates: [String: String] = [:]) {
    precondition(!url.isEmpty)
    self.url = url
    self.modifiedAt = modifiedAt
    self.alternates = alternates
  }
}

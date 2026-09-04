import Foundation

/// A deterministic native RSS and Atom feed.
public struct ContentFeed: Sendable {
  /// Feed title.
  public let title: String
  /// Absolute site URL.
  public let homeURL: String
  /// Feed entries in caller-selected order.
  public let items: [FeedItem]

  /// Creates a feed.
  public init(title: String, homeURL: String, items: [FeedItem]) {
    precondition(!title.isEmpty && !homeURL.isEmpty)
    self.title = title
    self.homeURL = homeURL
    self.items = items
  }

  /// Renders RSS 2.0 XML.
  public func rss() -> String {
    let entries = items.map { item in
      let description = item.summary.map { "<description>\($0.xmlEscaped)</description>" } ?? ""
      return
        "<item><title>\(item.title.xmlEscaped)</title><link>\(item.url.xmlEscaped)</link><guid isPermaLink=\"true\">\(item.url.xmlEscaped)</guid><pubDate>\(Self.rfc822(item.publishedAt))</pubDate>\(description)</item>"
    }.joined()
    return
      "<?xml version=\"1.0\" encoding=\"utf-8\"?><rss version=\"2.0\"><channel><title>\(title.xmlEscaped)</title><link>\(homeURL.xmlEscaped)</link>\(entries)</channel></rss>"
  }

  /// Renders Atom 1.0 XML.
  public func atom() -> String {
    let updated = items.map { $0.modifiedAt ?? $0.publishedAt }.max() ?? .distantPast
    let entries = items.map { item in
      let summary = item.summary.map { "<summary>\($0.xmlEscaped)</summary>" } ?? ""
      return
        "<entry><title>\(item.title.xmlEscaped)</title><id>\(item.url.xmlEscaped)</id><link href=\"\(item.url.xmlEscaped)\"/><published>\(Self.iso8601(item.publishedAt))</published><updated>\(Self.iso8601(item.modifiedAt ?? item.publishedAt))</updated>\(summary)</entry>"
    }.joined()
    return
      "<?xml version=\"1.0\" encoding=\"utf-8\"?><feed xmlns=\"http://www.w3.org/2005/Atom\"><title>\(title.xmlEscaped)</title><id>\(homeURL.xmlEscaped)</id><updated>\(Self.iso8601(updated))</updated>\(entries)</feed>"
  }

  private static func iso8601(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }

  private static func rfc822(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss Z"
    return formatter.string(from: date)
  }
}

extension String {
  package var xmlEscaped: String {
    replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&apos;")
  }
}

import Foundation

/// A deterministic XML sitemap.
public struct Sitemap: Sendable {
  /// Sitemap entries.
  public let entries: [SitemapEntry]

  /// Creates a sitemap sorted by canonical URL.
  public init(_ entries: [SitemapEntry]) { self.entries = entries.sorted { $0.url < $1.url } }

  /// Renders sitemap XML with alternate-language links.
  public func xml() -> String {
    let localized =
      entries.contains { !$0.alternates.isEmpty }
      ? " xmlns:xhtml=\"http://www.w3.org/1999/xhtml\"" : ""
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    let urls = entries.map { entry in
      let modified =
        entry.modifiedAt.map { "<lastmod>\(formatter.string(from: $0))</lastmod>" } ?? ""
      let alternates = entry.alternates.sorted { $0.key < $1.key }.map {
        "<xhtml:link rel=\"alternate\" hreflang=\"\($0.key.xmlEscaped)\" href=\"\($0.value.xmlEscaped)\"/>"
      }.joined()
      return "<url><loc>\(entry.url.xmlEscaped)</loc>\(modified)\(alternates)</url>"
    }.joined()
    return
      "<?xml version=\"1.0\" encoding=\"utf-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"\(localized)>\(urls)</urlset>"
  }
}

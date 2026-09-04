import Foundation
import RobinCore

/// Canonical and alternate URLs for one route in every configured locale.
public struct LocalizedRouteSet: Sendable {
  /// Supported locale identifiers in declaration order.
  public let locales: [String]
  /// The route without a locale prefix.
  public let path: String
  private let baseURL: URL

  /// Creates locale-prefixed routes beneath an absolute site URL.
  public init(baseURL: URL, path: String, locales: [String]) {
    precondition(baseURL.scheme == "https" || baseURL.scheme == "http")
    precondition(baseURL.host != nil && path.hasPrefix("/") && !locales.isEmpty)
    self.baseURL = baseURL
    self.path = path == "/" ? "" : path
    self.locales = locales
  }

  /// Returns the locale-specific route path.
  public func path(for locale: String) -> String {
    precondition(locales.contains(locale))
    return "/\(locale)\(path)"
  }

  /// Applies locale, canonical URL, and alternate-language links to metadata.
  public func metadata(_ metadata: Metadata, for locale: String) -> Metadata {
    var metadata = metadata
    metadata.language = locale
    metadata.canonicalURL = absoluteURL(for: locale)
    metadata.alternateLanguages = locales.map {
      .init($0, url: absoluteURL(for: $0))
    }
    return metadata
  }

  /// Creates locale, canonical URL, and alternate-language metadata.
  public func metadata(for locale: String) -> Metadata {
    metadata(Metadata(), for: locale)
  }

  private func absoluteURL(for locale: String) -> String {
    baseURL.appending(path: String(path(for: locale).dropFirst())).absoluteString
  }
}

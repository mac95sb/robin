import Foundation

/// Deterministic locale selection for routes, requests, jobs, and previews.
public struct LocaleNegotiator: Sendable {
  /// Supported locale identifiers.
  public let supported: [String]
  /// Fallback locale.
  public let defaultLocale: String

  /// Creates a negotiator with a required supported default locale.
  public init(supported: [String], defaultLocale: String) {
    precondition(!supported.isEmpty && supported.contains(defaultLocale))
    self.supported = supported
    self.defaultLocale = defaultLocale
  }

  /// Resolves route, user, header, then default preference.
  public func resolve(_ preference: LocalePreference) -> String {
    if let route = match(preference.route) { return route }
    if let user = match(preference.user) { return user }
    if let header = preference.acceptLanguage {
      for candidate in Self.headerCandidates(header) {
        if let locale = match(candidate) { return locale }
      }
    }
    return defaultLocale
  }

  private func match(_ candidate: String?) -> String? {
    guard let candidate else { return nil }
    if let exact = supported.first(where: { $0.caseInsensitiveCompare(candidate) == .orderedSame })
    {
      return exact
    }
    let language = candidate.split(separator: "-").first
    return supported.first {
      String($0.split(separator: "-").first ?? "")
        .caseInsensitiveCompare(String(language ?? "")) == .orderedSame
    }
  }

  private static func headerCandidates(_ header: String) -> [String] {
    var candidates: [(locale: String, quality: Double, index: Int)] = []
    for (index, item) in header.split(separator: ",").enumerated() {
      let parts = item.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
      let locale = parts[0].trimmingCharacters(in: .whitespaces)
      guard !locale.isEmpty, locale != "*" else { continue }
      let quality =
        parts.count == 2
        ? Double(parts[1].trimmingCharacters(in: .whitespaces).dropFirst(2)) ?? 0
        : 1
      guard quality > 0 else { continue }
      candidates.append((locale, quality, index))
    }
    return candidates.sorted {
      $0.quality == $1.quality ? $0.index < $1.index : $0.quality > $1.quality
    }.map(\.locale)
  }
}

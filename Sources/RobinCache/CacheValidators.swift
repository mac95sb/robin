import Foundation

/// HTTP conditional-request checks for a cached value.
public struct CacheValidators: Equatable, Sendable {
  /// The quoted entity tag.
  public let entityTag: String
  /// The source modification time.
  public let lastModified: Date

  /// Creates validators from cached metadata.
  public init(entityTag: String, lastModified: Date) {
    self.entityTag = entityTag
    self.lastModified = lastModified
  }

  /// Returns whether request validators permit a `304 Not Modified` response.
  ///
  /// `If-None-Match` takes precedence over `If-Modified-Since`, as required by HTTP.
  public func isNotModified(ifNoneMatch: String?, ifModifiedSince: Date?) -> Bool {
    if let ifNoneMatch {
      return ifNoneMatch.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        .contains { $0 == "*" || $0 == entityTag }
    }
    guard let ifModifiedSince else { return false }
    return lastModified.timeIntervalSince1970.rounded(.down)
      <= ifModifiedSince.timeIntervalSince1970.rounded(.down)
  }
}

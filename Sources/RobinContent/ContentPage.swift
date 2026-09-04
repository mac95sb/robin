/// One page from a content collection.
public struct ContentPage: Sendable {
  /// Documents on this page.
  public let documents: [ContentDocument]
  /// One-based page number.
  public let number: Int
  /// Total number of pages.
  public let totalPages: Int
  /// Whether a previous page exists.
  public var hasPrevious: Bool { number > 1 }
  /// Whether a next page exists.
  public var hasNext: Bool { number < totalPages }
  /// Previous one-based page number, when present.
  public var previousNumber: Int? { hasPrevious ? number - 1 : nil }
  /// Next one-based page number, when present.
  public var nextNumber: Int? { hasNext ? number + 1 : nil }

  /// Returns the stable static route for this page beneath a collection route.
  public func route(basePath: String) -> String {
    route(basePath: basePath, number: number)
  }

  package func route(basePath: String, number: Int) -> String {
    precondition(basePath.hasPrefix("/"))
    let base =
      basePath.count > 1 && basePath.hasSuffix("/") ? String(basePath.dropLast()) : basePath
    return number == 1 ? base : "\(base)/page/\(number)"
  }
}

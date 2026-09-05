/// Two routes that resolve to the same structural path and method.
public struct RouteConflict: Error, Equatable, Sendable {
  /// The identifier registered first.
  public let first: String
  /// The conflicting identifier registered second.
  public let second: String
}

/// A route after application API scoping has been resolved.
public struct RegisteredRoute: Equatable, Sendable {
  /// The stable registration identifier.
  public let identifier: String
  /// The fully scoped route pattern.
  public let pattern: RoutePattern
  /// The HTTP method for API routes.
  public let method: HTTPMethod?
  /// The external version for API routes.
  public let version: Version?

  /// Creates a resolved route registration.
  ///
  /// - Parameters:
  ///   - identifier: The stable registration identifier.
  ///   - pattern: The fully scoped route pattern.
  ///   - method: The HTTP method for an API route.
  ///   - version: The external API version.
  public init(
    _ identifier: String,
    pattern: RoutePattern,
    method: HTTPMethod? = nil,
    version: Version? = nil
  ) {
    self.identifier = identifier
    self.pattern = pattern
    self.method = method
    self.version = version
  }
}

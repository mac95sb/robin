/// A typed redirect from one route to another route with the same value type.
///
/// The value decoded from the source can be used to generate the destination location.
public struct RouteRedirect<Value: Sendable>: Sendable {
  /// The route whose matched value triggers the redirect.
  public let source: RouteDefinition<Value>

  /// The route used to generate the redirect destination.
  public let destination: RouteDefinition<Value>

  /// Whether the redirect is permanent rather than temporary.
  public let isPermanent: Bool

  /// Creates a redirect between routes that share a value type.
  ///
  /// - Parameters:
  ///   - source: The route whose matched value triggers the redirect.
  ///   - destination: The route used to generate the redirect location from that value.
  ///   - isPermanent: Whether the redirect is permanent. The default is `true`.
  public init(
    source: RouteDefinition<Value>,
    destination: RouteDefinition<Value>,
    isPermanent: Bool = true
  ) {
    self.source = source
    self.destination = destination
    self.isPermanent = isPermanent
  }

  /// Resolves a matching source path into an executable HTTP redirect result.
  public func response(for path: String) -> RedirectResponse? {
    guard let value = source.match(path) else { return nil }
    return RedirectResponse(
      statusCode: isPermanent ? 308 : 307,
      location: destination.url(for: value)
    )
  }
}

/// The transport-neutral result of executing a typed redirect.
public struct RedirectResponse: Equatable, Sendable {
  public let statusCode: Int
  public let location: String

  public init(statusCode: Int, location: String) {
    self.statusCode = statusCode
    self.location = location
  }
}

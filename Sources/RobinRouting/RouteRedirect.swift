/// A typed redirect from one route to another route with the same value type.
///
/// The value decoded from the source can be used to generate the destination location.
public struct RouteRedirect<Value: Sendable>: Sendable {
  /// The route whose matched value triggers the redirect.
  public let source: Route<Value>

  /// The route used to generate the redirect destination.
  public let destination: Route<Value>

  /// Whether the redirect is permanent rather than temporary.
  public let isPermanent: Bool

  /// Creates a redirect between routes that share a value type.
  ///
  /// - Parameters:
  ///   - source: The route whose matched value triggers the redirect.
  ///   - destination: The route used to generate the redirect location from that value.
  ///   - isPermanent: Whether the redirect is permanent. The default is `true`.
  public init(source: Route<Value>, destination: Route<Value>, isPermanent: Bool = true) {
    self.source = source
    self.destination = destination
    self.isPermanent = isPermanent
  }
}

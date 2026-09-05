import RobinCore

/// A JSON controller route that reuses ordinary matching and reverse-routing machinery.
public protocol APIRoute: Route {
  /// The HTTP method accepted by this route.
  var method: HTTPMethod { get }
  /// The optional external API version.
  var version: Version? { get }
}

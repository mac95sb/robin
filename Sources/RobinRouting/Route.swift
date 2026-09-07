import RobinCore

/// A typed route protocol shared by pages, controllers, redirects, and tooling.
public protocol Route: ApplicationRoute {
  /// The structural path shape used for registration.
  var pattern: RoutePattern { get }
}

extension Route {
  /// The structural path used for application registration.
  public var applicationRouteIdentifier: String { pattern.pathTemplate }
}

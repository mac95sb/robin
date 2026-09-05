import RobinCore

/// A typed route protocol shared by pages, controllers, redirects, and tooling.
public protocol Route: ApplicationRoute {
  /// Descriptive metadata used by inspection and documentation tooling.
  var metadata: RouteMetadata { get }
  /// The structural path shape used for registration.
  var pattern: RoutePattern { get }
}

extension Route {
  /// The operation identifier or structural path used for application registration.
  public var applicationRouteIdentifier: String {
    metadata.operationID ?? pattern.pathTemplate
  }
}

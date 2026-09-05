import RobinCore

/// A route-builder value that cannot enter the typed route registry.
public enum RouteRegistryError: Error, Equatable, Sendable {
  /// The identified application route does not conform to ``Route``.
  case unsupportedRoute(String)
  /// The supplied group prefix is empty or contains a traversal segment.
  case invalidGroup(String)
}

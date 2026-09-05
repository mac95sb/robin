import RobinCore

/// An empty controller-route registration.
public struct EmptyRoutes: Routes {
  /// The empty route collection.
  public let routes: [any ApplicationRoute] = []
  /// Creates an empty controller-route registration.
  public init() {}
}

/// An empty application-route registration.
public struct EmptyRoutes: Routes {
  /// The empty route collection.
  public let routes: [any ApplicationRoute] = []

  /// Creates an empty route registration.
  public init() {}
}

import RobinCore

/// A concrete, order-preserving registration produced by ``RoutesBuilder``.
public struct RouteList: Routes {
  /// The registered routes in source order.
  public let routes: [any ApplicationRoute]
  /// Creates a route registration.
  ///
  /// - Parameter routes: The routes in registration order.
  public init(routes: [any ApplicationRoute]) { self.routes = routes }
}

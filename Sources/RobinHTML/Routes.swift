import RobinCore

/// A typed collection of application routes registered by an ``App``.
public protocol Routes: Sendable {
  /// The registered routes in source order.
  var routes: [any ApplicationRoute] { get }
}

/// An empty controller-route registration.
public struct EmptyRoutes: Routes {
  /// The empty route collection.
  public let routes: [any ApplicationRoute] = []
  /// Creates an empty controller-route registration.
  public init() {}
}

/// A concrete, order-preserving registration produced by ``RoutesBuilder``.
public struct RouteList: Routes {
  /// The registered routes in source order.
  public let routes: [any ApplicationRoute]
  /// Creates a route registration.
  ///
  /// - Parameter routes: The routes in registration order.
  public init(routes: [any ApplicationRoute]) { self.routes = routes }
}

/// Builds route registrations with native Swift conditionals and loops.
@resultBuilder
public enum RoutesBuilder {
  /// Resolves a single application route into a registration.
  ///
  /// - Parameter expression: The route to register.
  /// - Returns: A registration containing only `expression`.
  public static func buildExpression<RouteType: ApplicationRoute>(_ expression: RouteType)
    -> RouteList
  {
    RouteList(routes: [expression])
  }

  /// Combines route registrations in source order.
  ///
  /// - Parameter components: The registrations in the block.
  /// - Returns: A flattened registration.
  public static func buildBlock(_ components: RouteList...) -> RouteList {
    RouteList(routes: components.flatMap(\.routes))
  }

  /// Builds a registration for an optional branch.
  ///
  /// - Parameter component: The branch registration, or `nil` when absent.
  /// - Returns: The branch registration or an empty registration.
  public static func buildOptional(_ component: RouteList?) -> RouteList {
    component ?? RouteList(routes: [])
  }

  /// Builds the first branch of a conditional.
  ///
  /// - Parameter component: The selected branch registration.
  /// - Returns: The supplied registration.
  public static func buildEither(first component: RouteList) -> RouteList { component }
  /// Builds the second branch of a conditional.
  ///
  /// - Parameter component: The selected branch registration.
  /// - Returns: The supplied registration.
  public static func buildEither(second component: RouteList) -> RouteList { component }
  /// Combines registrations produced by a loop.
  ///
  /// - Parameter components: The registrations produced by the loop.
  /// - Returns: A flattened registration in iteration order.
  public static func buildArray(_ components: [RouteList]) -> RouteList {
    RouteList(routes: components.flatMap(\.routes))
  }
}

import RobinCore

/// Builds route registrations with native Swift conditionals and loops.
@resultBuilder
public struct RoutesBuilder {
  /// Resolves a single application route into a registration.
  ///
  /// - Parameter expression: The route to register.
  /// - Returns: A registration containing only `expression`.
  public static func buildExpression<RouteType: ApplicationRoute>(_ expression: RouteType)
    -> RouteList
  {
    RouteList(routes: [expression])
  }

  /// Resolves a route collection into its registrations.
  ///
  /// - Parameter expression: The route collection to register.
  /// - Returns: A registration containing the collection's routes.
  public static func buildExpression<RouteCollection: Routes>(_ expression: RouteCollection)
    -> RouteList
  {
    RouteList(routes: expression.routes)
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

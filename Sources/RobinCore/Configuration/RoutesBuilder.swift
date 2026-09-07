/// Builds route registrations with native Swift conditionals and loops.
@resultBuilder
public struct RoutesBuilder {
  /// Resolves a single application route into a registration.
  public static func buildExpression<RouteType: ApplicationRoute>(_ expression: RouteType)
    -> RouteList
  {
    RouteList(routes: [expression])
  }

  /// Resolves a route collection into its registrations.
  public static func buildExpression<RouteCollection: Routes>(_ expression: RouteCollection)
    -> RouteList
  {
    RouteList(routes: expression.routes)
  }

  /// Combines route registrations in source order.
  public static func buildBlock(_ components: RouteList...) -> RouteList {
    RouteList(routes: components.flatMap(\.routes))
  }

  /// Builds a registration for an optional branch.
  public static func buildOptional(_ component: RouteList?) -> RouteList {
    component ?? RouteList(routes: [])
  }

  /// Builds the first branch of a conditional.
  public static func buildEither(first component: RouteList) -> RouteList { component }

  /// Builds the second branch of a conditional.
  public static func buildEither(second component: RouteList) -> RouteList { component }

  /// Combines registrations produced by a loop.
  public static func buildArray(_ components: [RouteList]) -> RouteList {
    RouteList(routes: components.flatMap(\.routes))
  }
}

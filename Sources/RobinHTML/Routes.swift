import RobinCore

public protocol Routes: Sendable {
  var routes: [any ApplicationRoute] { get }
}

public struct EmptyRoutes: Routes {
  public let routes: [any ApplicationRoute] = []
  public init() {}
}

public struct RouteList: Routes {
  public let routes: [any ApplicationRoute]
  public init(routes: [any ApplicationRoute]) { self.routes = routes }
}

@resultBuilder
public enum RoutesBuilder {
  public static func buildExpression<RouteType: ApplicationRoute>(_ expression: RouteType)
    -> RouteList
  {
    RouteList(routes: [expression])
  }

  public static func buildBlock(_ components: RouteList...) -> RouteList {
    RouteList(routes: components.flatMap(\.routes))
  }

  public static func buildOptional(_ component: RouteList?) -> RouteList {
    component ?? RouteList(routes: [])
  }

  public static func buildEither(first component: RouteList) -> RouteList { component }
  public static func buildEither(second component: RouteList) -> RouteList { component }
  public static func buildArray(_ components: [RouteList]) -> RouteList {
    RouteList(routes: components.flatMap(\.routes))
  }
}

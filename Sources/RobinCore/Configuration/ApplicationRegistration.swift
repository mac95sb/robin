/// A transport-neutral route registration consumed by application composition.
public protocol ApplicationRoute: Sendable {
  /// A stable identifier used for registration and conflict diagnostics.
  var applicationRouteIdentifier: String { get }
}

package protocol ApplicationRouteGroup: ApplicationRoute {
  var prefix: String { get }
  var routes: [any ApplicationRoute] { get }
}

package struct FlattenedApplicationRoute: Sendable {
  package let route: any ApplicationRoute
  package let prefixes: [String]
}

package func flattenedApplicationRoutes(
  _ routes: [any ApplicationRoute],
  prefixes: [String] = []
) -> [FlattenedApplicationRoute] {
  routes.flatMap { route in
    guard let group = route as? any ApplicationRouteGroup else {
      return [FlattenedApplicationRoute(route: route, prefixes: prefixes)]
    }
    return flattenedApplicationRoutes(group.routes, prefixes: prefixes + [group.prefix])
  }
}

package func routeGroupPathSegments(in prefix: String) -> [String]? {
  let segments = prefix.split(separator: "/").map(String.init)
  guard !segments.isEmpty, !segments.contains("."), !segments.contains("..") else { return nil }
  return segments
}

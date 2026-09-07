/// A transport-neutral route registration consumed by application composition.
public protocol ApplicationRoute: Sendable {
  /// A stable identifier used for registration and conflict diagnostics.
  var applicationRouteIdentifier: String { get }
}

/// A route registration that applies a shared path prefix to its child routes.
public protocol ApplicationRouteGroup: ApplicationRoute {
  /// The path prefix applied while registering child routes.
  var prefix: String { get }
  /// The child routes registered beneath ``prefix``.
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
    return flattenedApplicationRoutes(
      group.routes,
      prefixes: group.prefix.isEmpty ? prefixes : prefixes + [group.prefix])
  }
}

package func routeGroupPathSegments(in prefix: String) -> [String]? {
  if prefix.isEmpty { return [] }
  let segments = prefix.split(separator: "/").map(String.init)
  guard !segments.isEmpty, !segments.contains("."), !segments.contains("..") else { return nil }
  return segments
}

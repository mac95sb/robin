import RobinCore

/// The single resolved registry used for conflicts, API scoping, and inspection.
public struct RouteRegistry: Sendable {
  /// Routes in application registration order after API scoping.
  public let routes: [RegisteredRoute]

  /// Resolves typed routes and validates structural conflicts.
  ///
  /// - Parameters:
  ///   - routes: The typed routes to register.
  ///   - api: The shared API-root configuration.
  /// - Throws: ``RouteConflict`` when registrations overlap.
  public init(_ routes: [any Route], api: APIConfiguration = .default) throws {
    self.routes = routes.map { route in
      Self.register(route, prefixes: [], api: api)
    }
    try RouteConflictDetector.validate(self.routes)
  }

  private static func register(
    _ route: any Route,
    prefixes: [RoutePattern.Segment],
    api: APIConfiguration
  ) -> RegisteredRoute {
    let apiRoute = route as? any APIRoute
    let prefix =
      apiRoute.map { _ in
        api.root.value.split(separator: "/").map { RoutePattern.Segment.literal(String($0)) }
      } ?? []
    let version = apiRoute?.version
    let versionSegment = version.map { [RoutePattern.Segment.literal("v\($0.number)")] } ?? []
    return RegisteredRoute(
      route.applicationRouteIdentifier,
      pattern: RoutePattern(prefix + versionSegment + prefixes + route.pattern.segments),
      metadata: route.metadata,
      method: apiRoute?.method,
      version: version
    )
  }

  /// Resolves the application's erased route-builder output into this single typed registry.
  ///
  /// - Parameters:
  ///   - applicationRoutes: The erased routes produced by the application builder.
  ///   - api: The shared API-root configuration.
  /// - Throws: ``RouteRegistryError`` for an unsupported route or ``RouteConflict`` for overlap.
  public init(
    applicationRoutes: [any ApplicationRoute],
    api: APIConfiguration = .default
  ) throws {
    routes = try flattenedApplicationRoutes(applicationRoutes).map { registration in
      guard let route = registration.route as? any Route else {
        throw RouteRegistryError.unsupportedRoute(registration.route.applicationRouteIdentifier)
      }
      let prefixes = try registration.prefixes.flatMap { prefix in
        guard let segments = routeGroupPathSegments(in: prefix) else {
          throw RouteRegistryError.invalidGroup(prefix)
        }
        return segments.map(RoutePattern.Segment.literal)
      }
      return Self.register(route, prefixes: prefixes, api: api)
    }
    try RouteConflictDetector.validate(routes)
  }
}

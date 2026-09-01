import RobinCore

/// The single resolved registry used for conflicts, API scoping, inspection, and OpenAPI output.
public struct RouteRegistry: Sendable {
  public let routes: [RegisteredRoute]

  public init(_ routes: [any Route], api: APIConfiguration = .default) throws {
    self.routes = routes.map { route in
      let apiRoute = route as? any APIRoute
      let prefix =
        apiRoute.map { _ in
          api.root.value.split(separator: "/").map { RoutePattern.Segment.literal(String($0)) }
        } ?? []
      let version = apiRoute?.version
      let versionSegment = version.map { [RoutePattern.Segment.literal("v\($0.number)")] } ?? []
      return RegisteredRoute(
        route.applicationRouteIdentifier,
        pattern: RoutePattern(prefix + versionSegment + route.pattern.segments),
        metadata: route.metadata,
        method: apiRoute?.method,
        version: version
      )
    }
    try RouteConflictDetector.validate(self.routes)
  }

  /// Resolves the application's erased route-builder output into this single typed registry.
  public init(
    applicationRoutes: [any ApplicationRoute],
    api: APIConfiguration = .default
  ) throws {
    let routes = try applicationRoutes.map { route in
      guard let typed = route as? any Route else {
        throw RouteRegistryError.unsupportedRoute(route.applicationRouteIdentifier)
      }
      return typed
    }
    try self.init(routes, api: api)
  }

  /// Produces the deterministic OpenAPI model directly from registered API routes.
  public func openAPIDocument(title: String, version: String) -> OpenAPIDocument {
    OpenAPIDocument(
      title: title,
      version: version,
      operations: routes.compactMap { route in
        guard let method = route.method else { return nil }
        return .init(
          method: method,
          pattern: route.pattern,
          metadata: route.metadata,
          version: route.version
        )
      }
    )
  }
}

public enum RouteRegistryError: Error, Equatable, Sendable {
  case unsupportedRoute(String)
}

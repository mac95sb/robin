import RobinCore

/// A typed route protocol shared by pages, controllers, redirects, and tooling.
public protocol Route: ApplicationRoute {
  /// Descriptive metadata used by inspection and documentation tooling.
  var metadata: RouteMetadata { get }
  /// The structural path shape used for registration.
  var pattern: RoutePattern { get }
}

extension Route {
  /// The operation identifier or structural path used for application registration.
  public var applicationRouteIdentifier: String {
    metadata.operationID ?? pattern.pathTemplate
  }
}

/// A JSON controller route that reuses ordinary matching and reverse-routing machinery.
public protocol APIRoute: Route {
  /// The HTTP method accepted by this route.
  var method: HTTPMethod { get }
  /// The optional external API version.
  var version: Version? { get }
}

/// A concrete API route backed by typed path, request, and response contracts.
public struct APIEndpoint<Value, Request, Response>: APIRoute, Sendable
where Value: Sendable, Request: Decodable & Sendable, Response: Encodable & Sendable {
  /// The typed path definition.
  public let route: RouteDefinition<Value>
  /// The HTTP method accepted by the endpoint.
  public let method: HTTPMethod
  /// The optional external API version.
  public let version: Version?

  /// Creates a typed API endpoint description.
  ///
  /// - Parameters:
  ///   - route: The typed API-root-relative route.
  ///   - method: The accepted HTTP method.
  ///   - version: An optional external API version.
  public init(
    _ route: RouteDefinition<Value>,
    method: HTTPMethod,
    version: Version? = .default
  ) {
    self.route = route
    self.method = method
    self.version = version
  }

  /// The route metadata used by inspection and documentation tooling.
  public var metadata: RouteMetadata { route.metadata }
  /// The endpoint's API-root-relative path pattern.
  public var pattern: RoutePattern { route.pattern }
}

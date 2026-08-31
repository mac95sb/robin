import RobinCore

/// A typed route protocol shared by pages, controllers, redirects, and tooling.
public protocol Route: ApplicationRoute {
  var metadata: RouteMetadata { get }
  var pattern: RoutePattern { get }
}

extension Route {
  public var applicationRouteIdentifier: String {
    metadata.operationID ?? pattern.openAPIPath
  }

  public var isAPIRoute: Bool { false }
  public var openAPIMethod: OpenAPIDocument.Method? { nil }
  public var apiVersion: Version? { nil }
}

/// A JSON controller route that reuses ordinary matching and reverse-routing machinery.
public protocol APIRoute: Route {
  associatedtype Request: Decodable & Sendable
  associatedtype Response: Encodable & Sendable

  var method: OpenAPIDocument.Method { get }
  var version: Version? { get }
}

extension APIRoute {
  public var isAPIRoute: Bool { true }
  public var openAPIMethod: OpenAPIDocument.Method? { method }
  public var apiVersion: Version? { version }
}

/// A concrete API route backed by typed path, request, and response contracts.
public struct APIEndpoint<Value, Request, Response>: APIRoute, Sendable
where Value: Sendable, Request: Decodable & Sendable, Response: Encodable & Sendable {
  public let route: RouteDefinition<Value>
  public let method: OpenAPIDocument.Method
  public let version: Version?

  public init(
    _ route: RouteDefinition<Value>,
    method: OpenAPIDocument.Method,
    version: Version? = nil
  ) {
    self.route = route
    self.method = method
    self.version = version
  }

  public var metadata: RouteMetadata { route.metadata }
  public var pattern: RoutePattern { route.pattern }
}

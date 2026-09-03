import Foundation
import RobinRouting

/// A typed JSON route that handles requests through ``ApplicationResponder``.
public protocol Controller: APIRoute, ServerRoute {
  /// The value decoded from the matched path.
  associatedtype Value: Sendable
  /// The route representation declared by the controller.
  associatedtype RouteRepresentation: Sendable
  /// The decoded request-body contract.
  associatedtype Request: Decodable & Sendable
  /// The encoded response-body contract.
  associatedtype Response: Encodable & Sendable

  /// The path matched by this controller.
  var route: RouteRepresentation { get }

  /// Handles a matched and decoded request.
  ///
  /// - Parameters:
  ///   - value: The value decoded from the matched path.
  ///   - request: The decoded request body.
  ///   - context: Metadata and services associated with the request.
  /// - Returns: The response body to encode.
  /// - Throws: An error when the request cannot be handled.
  func handle(
    _ value: Value,
    request: Request,
    context: RequestContext
  ) async throws -> Response
}

extension Controller {
  /// The HTTP method accepted by this controller.
  public var method: OpenAPIDocument.Method { .get }
  /// The optional API version prefix.
  public var version: Version? { nil }
  /// Transport features required by this controller.
  public var requiredCapabilities: TransportCapabilities { [] }

  private func respond(
    to request: RobinServer.Request,
    context: RequestContext,
    api: APIConfiguration,
    route: RouteDefinition<Value>
  ) async throws -> RobinServer.Response? {
    guard method.matches(request.method.rawValue) else { return nil }
    guard let path = relativePath(request.path, api: api, version: version) else { return nil }
    guard let value = route.match(path) else { return nil }
    if !request.body.isEmpty,
      request.header(.contentType)?.lowercased().contains("application/json") != true
    {
      throw ServerError(.unsupportedMediaType, "The request body must use application/json.")
    }
    if let accept = request.header(.accept)?.lowercased(),
      !accept.contains("application/json"), !accept.contains("*/*")
    {
      throw ServerError(.notAcceptable, "The requested response representation is unavailable.")
    }

    let input: Request
    do {
      input = try JSONDecoder().decode(
        Request.self,
        from: request.body.isEmpty ? Data("{}".utf8) : Data(request.body)
      )
    } catch {
      throw ServerError(.badRequest, "The request body is not valid JSON.")
    }
    return try RobinServer.Response.json(
      try await handle(value, request: input, context: context)
    )
  }
}

extension Controller where RouteRepresentation == RouteDefinition<Value> {
  /// Metadata used for conflicts, inspection, and OpenAPI output.
  public var metadata: RouteMetadata { route.metadata }
  /// The controller's API-root-relative route pattern.
  public var pattern: RoutePattern { route.pattern }

  /// Decodes and executes a matching JSON request.
  ///
  /// - Returns: The encoded response, or `nil` when the method or route does not match.
  /// - Throws: ``ServerError`` for negotiation and decoding failures, or a handler error.
  public func respond(
    to request: RobinServer.Request,
    context: RequestContext,
    api: APIConfiguration
  ) async throws -> RobinServer.Response? {
    try await respond(to: request, context: context, api: api, route: route)
  }
}

extension Controller where RouteRepresentation == String, Value == Void {
  private var routeDefinition: RouteDefinition<Void> { .path(route) }

  /// Metadata used for conflicts, inspection, and OpenAPI output.
  public var metadata: RouteMetadata { routeDefinition.metadata }
  /// The controller's API-root-relative route pattern.
  public var pattern: RoutePattern { routeDefinition.pattern }

  /// Decodes and executes a matching JSON request.
  ///
  /// - Returns: The encoded response, or `nil` when the method or route does not match.
  /// - Throws: ``ServerError`` for negotiation and decoding failures, or a handler error.
  public func respond(
    to request: RobinServer.Request,
    context: RequestContext,
    api: APIConfiguration
  ) async throws -> RobinServer.Response? {
    try await respond(to: request, context: context, api: api, route: routeDefinition)
  }
}

/// The request body type for controllers that accept no JSON fields.
public struct EmptyRequest: Codable, Sendable {
  /// Creates an empty request value.
  public init() {}
}

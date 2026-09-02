import Foundation
import RobinRouting

/// A typed JSON controller route executed by ``ApplicationResponder``.
public struct Controller<Value, Input, Output>: APIRoute, Sendable
where
  Value: Sendable,
  Input: Decodable & Sendable,
  Output: Encodable & Sendable
{
  /// The decoded JSON request type.
  public typealias Request = Input
  /// The encoded JSON response type.
  public typealias Response = Output

  /// The typed path matched by this controller.
  public let route: RouteDefinition<Value>
  /// The HTTP method accepted by this controller.
  public let method: OpenAPIDocument.Method
  /// The optional API version prefix.
  public let version: Version?
  private let handler: @Sendable (Value, Input, RequestContext) async throws -> Output

  /// Creates a typed JSON controller.
  ///
  /// - Parameters:
  ///   - route: The typed, API-root-relative route.
  ///   - method: The accepted HTTP method.
  ///   - version: An optional externally maintained API version.
  ///   - handler: The operation invoked with matched path values, decoded JSON, and request context.
  public init(
    _ route: RouteDefinition<Value>,
    method: OpenAPIDocument.Method,
    version: Version? = nil,
    handler: @escaping @Sendable (Value, Input, RequestContext) async throws -> Output
  ) {
    self.route = route
    self.method = method
    self.version = version
    self.handler = handler
  }

  /// Metadata used for conflicts, inspection, and OpenAPI output.
  public var metadata: RouteMetadata { route.metadata }
  /// The controller's API-root-relative route pattern.
  public var pattern: RoutePattern { route.pattern }
}

extension Controller: ServerRoute {
  public var requiredCapabilities: TransportCapabilities { [] }

  /// Decodes and executes a matching JSON request.
  ///
  /// - Returns: The encoded response, or `nil` when the method or route does not match.
  /// - Throws: ``ServerError`` for negotiation and decoding failures, or a handler error.
  public func respond(
    to request: RobinServer.Request,
    context: RequestContext,
    api: APIConfiguration
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

    let input: Input
    do {
      input = try JSONDecoder().decode(
        Input.self,
        from: request.body.isEmpty ? Data("{}".utf8) : Data(request.body)
      )
    } catch {
      throw ServerError(.badRequest, "The request body is not valid JSON.")
    }
    return try RobinServer.Response.json(try await handler(value, input, context))
  }
}

/// The request body type for controllers that accept no JSON fields.
public struct EmptyRequest: Codable, Sendable {
  /// Creates an empty request value.
  public init() {}
}

extension Controller where Input == EmptyRequest {
  /// Creates a controller that accepts no JSON fields.
  ///
  /// - Parameters:
  ///   - route: The typed, API-root-relative route.
  ///   - method: The accepted HTTP method.
  ///   - version: An optional externally maintained API version.
  ///   - handler: The operation invoked with matched path values and request context.
  public init(
    _ route: RouteDefinition<Value>,
    method: OpenAPIDocument.Method,
    version: Version? = nil,
    handler: @escaping @Sendable (Value, RequestContext) async throws -> Output
  ) {
    self.init(route, method: method, version: version) { value, _, context in
      try await handler(value, context)
    }
  }
}

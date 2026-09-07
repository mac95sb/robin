import RobinCore
import RobinRouting

private struct RouteHandler<
  Value: Sendable, Request: Decodable & Sendable, Response: Encodable & Sendable
>: Endpoint {
  let route: RouteDefinition<Value>
  let method: HTTPMethod
  let version: Version?
  let operation: @Sendable (Value, Request, RequestContext) async throws -> Response

  func handle(
    _ value: Value,
    request: Request,
    context: RequestContext
  ) async throws -> Response {
    try await operation(value, request, context)
  }
}

extension RouteDefinition {
  /// Registers a GET handler for this route.
  ///
  /// Use a method reference for a controller handler, such as
  /// `RouteDefinition.path("todos").get(use: list)`.
  ///
  /// - Parameters:
  ///   - version: The optional API version prefix.
  ///   - operation: The function that handles the matched path.
  /// - Returns: An endpoint registered with the GET method.
  public func get<Response: Encodable & Sendable>(
    version: Version? = .default,
    use operation: @escaping @Sendable (Value, RequestContext) async throws -> Response
  ) -> some Endpoint {
    RouteHandler<Value, EmptyRequest, Response>(
      route: self,
      method: .get,
      version: version,
      operation: { (value: Value, _: EmptyRequest, context: RequestContext) in
        try await operation(value, context)
      }
    )
  }

  /// Registers a POST handler for this route.
  ///
  /// - Parameters:
  ///   - request: The request body type decoded from JSON.
  ///   - version: The optional API version prefix.
  ///   - operation: The function that handles the matched path and decoded body.
  /// - Returns: An endpoint registered with the POST method.
  public func post<Request: Decodable & Sendable, Response: Encodable & Sendable>(
    request: Request.Type,
    version: Version? = .default,
    use operation: @escaping @Sendable (Value, Request, RequestContext) async throws -> Response
  ) -> some Endpoint {
    RouteHandler(route: self, method: .post, version: version, operation: operation)
  }

  /// Registers a PUT handler for this route.
  ///
  /// - Parameters:
  ///   - request: The request body type decoded from JSON.
  ///   - version: The optional API version prefix.
  ///   - operation: The function that handles the matched path and decoded body.
  /// - Returns: An endpoint registered with the PUT method.
  public func put<Request: Decodable & Sendable, Response: Encodable & Sendable>(
    request: Request.Type,
    version: Version? = .default,
    use operation: @escaping @Sendable (Value, Request, RequestContext) async throws -> Response
  ) -> some Endpoint {
    RouteHandler(route: self, method: .put, version: version, operation: operation)
  }

  /// Registers a PATCH handler for this route.
  ///
  /// - Parameters:
  ///   - request: The request body type decoded from JSON.
  ///   - version: The optional API version prefix.
  ///   - operation: The function that handles the matched path and decoded body.
  /// - Returns: An endpoint registered with the PATCH method.
  public func patch<Request: Decodable & Sendable, Response: Encodable & Sendable>(
    request: Request.Type,
    version: Version? = .default,
    use operation: @escaping @Sendable (Value, Request, RequestContext) async throws -> Response
  ) -> some Endpoint {
    RouteHandler(route: self, method: .patch, version: version, operation: operation)
  }

  /// Registers a DELETE handler for this route.
  ///
  /// - Parameters:
  ///   - version: The optional API version prefix.
  ///   - operation: The function that handles the matched path.
  /// - Returns: An endpoint registered with the DELETE method.
  public func delete<Response: Encodable & Sendable>(
    version: Version? = .default,
    use operation: @escaping @Sendable (Value, RequestContext) async throws -> Response
  ) -> some Endpoint {
    RouteHandler<Value, EmptyRequest, Response>(
      route: self,
      method: .delete,
      version: version,
      operation: { (value: Value, _: EmptyRequest, context: RequestContext) in
        try await operation(value, context)
      }
    )
  }
}

/// A GET endpoint for a route group's root or one typed path parameter.
public struct GET<Value: Sendable, Response: Encodable & Sendable>: Endpoint {
  /// The route matched by this endpoint.
  public let route: RouteDefinition<Value>
  /// The API version prefix.
  public let version: Version?
  private let operation: @Sendable (Value, RequestContext) async throws -> Response

  /// Creates a GET endpoint at a route group's root path.
  ///
  /// - Parameters:
  ///   - version: The optional API version prefix.
  ///   - operation: The function that handles the request.
  public init(
    version: Version? = .default,
    use operation: @escaping @Sendable (Void, RequestContext) async throws -> Response
  ) where Value == Void {
    self.route = .path()
    self.version = version
    self.operation = operation
  }

  /// Creates a GET endpoint with one typed path parameter.
  ///
  /// - Parameters:
  ///   - parameter: The codec used to decode the path segment.
  ///   - version: The optional API version prefix.
  ///   - operation: The function that handles the decoded parameter.
  public init(
    _ parameter: PathParameter<Value>,
    version: Version? = .default,
    use operation: @escaping @Sendable (Value, RequestContext) async throws -> Response
  ) {
    self.route = .path(parameter: parameter)
    self.version = version
    self.operation = operation
  }

  /// Creates a GET endpoint with one string path parameter.
  ///
  /// Write the parameter using a leading colon, such as `GET(":id", use: show)`.
  public init(
    _ parameter: String,
    version: Version? = .default,
    use operation: @escaping @Sendable (String, RequestContext) async throws -> Response
  ) where Value == String {
    precondition(
      parameter.first == ":" && parameter.count > 1,
      "A path parameter must begin with ':' and have a name."
    )
    self.route = .path(parameter: .string(String(parameter.dropFirst())))
    self.version = version
    self.operation = operation
  }

  /// Handles the matched request.
  public func handle(_ value: Value, request _: EmptyRequest, context: RequestContext) async throws
    -> Response
  {
    try await operation(value, context)
  }
}

/// A POST endpoint for a route group's root path.
public struct POST<Request: Decodable & Sendable, Response: Encodable & Sendable>: Endpoint {
  /// The route matched by this endpoint.
  public let route: RouteDefinition<Void>
  /// The API version prefix.
  public let version: Version?
  private let operation: @Sendable (Void, Request, RequestContext) async throws -> Response

  /// Creates a POST endpoint at a route group's root path.
  ///
  /// - Parameters:
  ///   - request: The request body type decoded from JSON.
  ///   - version: The optional API version prefix.
  ///   - operation: The function that handles the decoded request body.
  public init(
    request: Request.Type,
    version: Version? = .default,
    use operation: @escaping @Sendable (Void, Request, RequestContext) async throws -> Response
  ) {
    self.route = .path()
    self.version = version
    self.operation = operation
  }

  /// Creates a POST endpoint that decodes a resource's client-supplied properties.
  ///
  /// Apply ``RobinRouting/Resource()`` to the resource. The handler receives the complete
  /// resource, including values created from its declared defaults.
  public init<Resource: ResourceRepresentable>(
    _ resource: Resource.Type,
    version: Version? = .default,
    use operation: @escaping @Sendable (Void, Resource, RequestContext) async throws -> Response
  ) where Request == Resource.Create {
    self.route = .path()
    self.version = version
    self.operation = { value, request, context in
      try await operation(value, Resource(create: request), context)
    }
  }

  /// The HTTP method accepted by this endpoint.
  public let method: HTTPMethod = .post

  /// Handles the matched request.
  public func handle(_: Void, request: Request, context: RequestContext) async throws -> Response {
    try await operation((), request, context)
  }
}

import RobinRouting

/// A WebSocket endpoint at a route group's root path.
public struct WebSocketRoute: APIRoute, ServerRoute {
  /// The endpoint's API version prefix.
  public let version: Version?
  /// Transport features required by the endpoint, including WebSocket support.
  public let requiredCapabilities: TransportCapabilities
  private let operation: @Sendable (RequestContext) async throws -> WebSocketSession

  /// Creates a WebSocket endpoint at a route group's root path.
  ///
  /// - Parameters:
  ///   - version: The optional API version prefix.
  ///   - requiredCapabilities: Additional transport features required by the endpoint.
  ///   - operation: A function that creates the session for an accepted connection.
  public init(
    version: Version? = .default,
    requiredCapabilities: TransportCapabilities = [],
    use operation: @escaping @Sendable (RequestContext) async throws -> WebSocketSession
  ) {
    self.version = version
    self.requiredCapabilities = requiredCapabilities.union(.webSockets)
    self.operation = operation
  }

  /// The GET method used for the HTTP upgrade request.
  public let method = HTTPMethod.get
  /// The route group's root path.
  public let pattern = RoutePattern([])

  /// Responds to a matching WebSocket upgrade request.
  ///
  /// - Parameters:
  ///   - request: The normalized upgrade request.
  ///   - context: Values scoped to the request.
  ///   - api: The application's API path configuration.
  /// - Returns: A WebSocket response when the GET path matches, or `nil` otherwise.
  /// - Throws: An error raised while creating the session.
  public func respond(
    to request: Request,
    context: RequestContext,
    api: APIConfiguration
  ) async throws -> Response? {
    guard request.method == .get, relativePath(request.path, api: api, version: version) == "/"
    else { return nil }
    return .webSocket(try await operation(context))
  }
}

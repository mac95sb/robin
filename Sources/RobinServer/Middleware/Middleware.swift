/// A request middleware with an explicit next responder.
public struct Middleware: Sendable {
  /// Transport features required by this middleware.
  public let requiredCapabilities: TransportCapabilities
  /// The remainder of the middleware chain.
  public struct Next: Sendable {
    private let operation: @Sendable (Request, RequestContext) async throws -> Response

    init(
      _ operation: @escaping @Sendable (Request, RequestContext) async throws -> Response
    ) {
      self.operation = operation
    }

    /// Continues processing with the supplied request and context.
    public func respond(to request: Request, context: RequestContext) async throws -> Response {
      try await operation(request, context)
    }
  }

  private let operation: @Sendable (Request, RequestContext, Next) async throws -> Response

  /// Creates middleware from an asynchronous operation.
  ///
  /// The operation may return a response directly or invoke `next` to continue the chain.
  public init(
    requiredCapabilities: TransportCapabilities = [],
    _ operation: @escaping @Sendable (Request, RequestContext, Next) async throws -> Response
  ) {
    self.requiredCapabilities = requiredCapabilities
    self.operation = operation
  }

  func respond(
    to request: Request,
    context: RequestContext,
    next: Next
  ) async throws -> Response {
    try await operation(request, context, next)
  }
}

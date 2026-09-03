import RobinHTML
import RobinRouting

/// Runs one application request through generated WASI HTTP bindings.
public struct WASIRuntime<Adapter: WASIHostAdapter>: Sendable {
  private let responder: ApplicationResponder
  private let adapter: Adapter

  /// Creates a WASI runtime for an application.
  ///
  /// - Parameters:
  ///   - application: The API or server-rendered application to run.
  ///   - adapter: The generated host-binding adapter.
  ///   - api: The prefix and versioning policy for API routes.
  ///   - middleware: Middleware applied in array order.
  ///   - errorResponses: Application-specific 404 and 500 response rendering.
  /// - Throws: A composition, route, or missing-capability diagnostic.
  public init<Application: App>(
    _ application: Application,
    adapter: Adapter,
    api: APIConfiguration = .default,
    middleware: [Middleware] = [],
    errorResponses: ErrorResponses = .init()
  ) throws {
    self.responder = try ApplicationResponder(
      application,
      api: api,
      middleware: [.deadline] + middleware,
      errorResponses: errorResponses,
      transportCapabilities: .invocation
    )
    self.adapter = adapter
  }

  /// Handles one incoming WASI HTTP request.
  ///
  /// - Parameters:
  ///   - incoming: The request received from generated host bindings.
  ///   - context: Request-scoped transport values, when available.
  /// - Returns: The response represented by the host's generated binding type.
  /// - Throws: An adapter error when the request or response cannot be represented.
  public func respond(
    to incoming: Adapter.IncomingRequest,
    context: RequestContext? = nil
  ) async throws -> Adapter.OutgoingResponse {
    let request = try adapter.request(from: incoming)
    return try adapter.response(from: await responder.respond(to: request, context: context))
  }
}

import RobinHTML
import RobinRouting

/// Runs an application through a provider invocation channel.
public struct InvocationRuntime: Sendable {
  private let responder: ApplicationResponder
  private let codec: any InvocationEventCodec

  /// Creates an invocation runtime for an application.
  ///
  /// - Parameters:
  ///   - application: The API or server-rendered application to run.
  ///   - codec: The provider event-envelope codec.
  ///   - api: The prefix and versioning policy for API routes.
  ///   - middleware: Middleware applied in array order.
  ///   - errorResponses: Application-specific 404 and 500 response rendering.
  ///   - transportCapabilities: Features preserved by the invocation host.
  /// - Throws: A composition, route, or missing-capability diagnostic.
  public init<Application: App>(
    _ application: Application,
    codec: any InvocationEventCodec,
    api: APIConfiguration = .default,
    middleware: [Middleware] = [],
    errorResponses: ErrorResponses = .init(),
    transportCapabilities: TransportCapabilities = .invocation
  ) throws {
    self.responder = try ApplicationResponder(
      application,
      api: api,
      middleware: [.deadline] + middleware,
      errorResponses: errorResponses,
      transportCapabilities: transportCapabilities
    )
    self.codec = codec
  }

  /// Handles one provider event.
  ///
  /// - Parameter event: The raw event and provider invocation context.
  /// - Returns: The encoded provider response envelope.
  /// - Throws: A codec error when the event or response cannot be represented.
  public func respond(to event: InvocationEvent) async throws -> [UInt8] {
    let invocation = try codec.decode(event.payload)
    let context = RequestContext(
      requestID: invocation.requestID ?? event.id,
      clientAddress: invocation.clientAddress,
      deadline: event.deadline
    )
    return try codec.encode(await responder.respond(to: invocation.request, context: context))
  }

  /// Runs until the invocation channel closes or the task is cancelled.
  ///
  /// Event-specific failures are reported to the channel and do not stop later invocations.
  ///
  /// - Parameter channel: The provider invocation channel.
  /// - Throws: A channel error or Swift cancellation error.
  public func run(using channel: any InvocationChannel) async throws {
    while true {
      try Task.checkCancellation()
      guard let event = try await channel.next() else { return }
      do {
        let payload = try await respond(to: event)
        try await channel.respond(to: event.id, with: payload)
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        let message = String(describing: error)
        try await channel.fail(
          invocationID: event.id,
          with: message.isEmpty ? "Invocation failed." : message
        )
      }
    }
  }
}

/// Receives events and completes them through a provider invocation API.
public protocol InvocationChannel: Sendable {
  /// Waits for the next invocation, or returns `nil` when the channel has closed.
  ///
  /// - Returns: The next event, or `nil` after the channel closes.
  /// - Throws: A transport error when the next event cannot be received.
  func next() async throws -> InvocationEvent?

  /// Completes an invocation successfully.
  ///
  /// - Parameters:
  ///   - invocationID: The provider's stable invocation identifier.
  ///   - payload: The encoded response envelope.
  /// - Throws: A transport error when completion cannot be reported.
  func respond(to invocationID: String, with payload: [UInt8]) async throws

  /// Completes an invocation with a runtime or codec failure.
  ///
  /// - Parameters:
  ///   - invocationID: The provider's stable invocation identifier.
  ///   - message: The nonempty failure diagnostic safe to send to the provider.
  /// - Throws: A transport error when failure cannot be reported.
  func fail(invocationID: String, with message: String) async throws
}

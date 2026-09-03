import Foundation

/// One raw event received from an invocation transport.
public struct InvocationEvent: Sendable {
  /// The provider's stable invocation identifier.
  public let id: String
  /// The provider event bytes decoded by an ``InvocationEventCodec``.
  public let payload: [UInt8]
  /// The instant after which request work should stop.
  public let deadline: ContinuousClock.Instant?

  /// Creates an invocation event.
  ///
  /// - Parameters:
  ///   - id: The provider's stable invocation identifier.
  ///   - payload: The provider event bytes.
  ///   - deadline: The instant after which request work should stop.
  ///
  /// - Precondition: `id` contains a non-whitespace character.
  public init(id: String, payload: [UInt8], deadline: ContinuousClock.Instant? = nil) {
    precondition(id.contains { !$0.isWhitespace })
    self.id = id
    self.payload = payload
    self.deadline = deadline
  }
}

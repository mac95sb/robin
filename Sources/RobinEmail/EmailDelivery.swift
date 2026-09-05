import Foundation

/// Successful delivery metadata returned by an email transport.
public struct EmailDelivery: Equatable, Sendable {
  /// Framework message identifier.
  public let messageID: String
  /// Time the transport accepted the message.
  public let acceptedAt: Date
  /// Provider response identifier, when one exists.
  public let providerID: String?

  /// Creates delivery metadata.
  public init(messageID: String, acceptedAt: Date, providerID: String? = nil) {
    self.messageID = messageID
    self.acceptedAt = acceptedAt
    self.providerID = providerID
  }
}

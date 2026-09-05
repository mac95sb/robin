/// Redacted delivery facts safe for application logs.
public struct EmailDeliveryLog: Equatable, Sendable {
  /// Framework message identifier.
  public let messageID: String
  /// Number of envelope recipients; addresses are deliberately omitted.
  public let recipientCount: Int
  /// Whether delivery succeeded.
  public let delivered: Bool
  /// Redacted error type, with no message content or credentials.
  public let errorType: String?
}

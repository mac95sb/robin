import Foundation

/// A captured development delivery.
public struct DevelopmentEmail: Sendable {
  /// Message shown by the preview.
  public let message: EmailMessage
  /// SMTP/provider envelope used for delivery.
  public let envelope: EmailEnvelope
  /// Capture time.
  public let receivedAt: Date
}

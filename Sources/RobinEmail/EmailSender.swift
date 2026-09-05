/// Transport-neutral transactional email delivery.
public protocol EmailSender: Sendable {
  /// Sends one message using a separate SMTP/provider envelope.
  func send(_ message: EmailMessage, envelope: EmailEnvelope) async throws -> EmailDelivery
}

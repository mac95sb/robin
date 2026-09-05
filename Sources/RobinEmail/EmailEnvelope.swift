/// SMTP routing kept separate from visible message headers.
public struct EmailEnvelope: Sendable {
  /// SMTP `MAIL FROM` address.
  public let sender: EmailAddress
  /// SMTP `RCPT TO` addresses, including blind-copy recipients.
  public let recipients: [EmailAddress]

  /// Creates a delivery envelope.
  public init(sender: EmailAddress, recipients: [EmailAddress]) {
    precondition(!recipients.isEmpty)
    self.sender = sender
    self.recipients = recipients
  }
}

/// Adds PII- and secret-redacted logging to any email sender.
public struct LoggingEmailSender: EmailSender {
  /// Receives redacted delivery facts.
  public typealias Observer = @Sendable (EmailDeliveryLog) -> Void

  private let sender: any EmailSender
  private let observer: Observer

  /// Wraps a sender with redacted delivery logging.
  public init(sender: any EmailSender, observer: @escaping Observer) {
    self.sender = sender
    self.observer = observer
  }

  /// Sends a message and reports only non-sensitive facts.
  public func send(_ message: EmailMessage, envelope: EmailEnvelope) async throws -> EmailDelivery {
    do {
      let delivery = try await sender.send(message, envelope: envelope)
      observer(
        EmailDeliveryLog(
          messageID: message.id, recipientCount: envelope.recipients.count,
          delivered: true, errorType: nil))
      return delivery
    } catch {
      observer(
        EmailDeliveryLog(
          messageID: message.id, recipientCount: envelope.recipients.count,
          delivered: false, errorType: String(reflecting: type(of: error))))
      throw error
    }
  }
}

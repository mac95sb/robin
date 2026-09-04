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

/// Transport-neutral transactional email delivery.
public protocol EmailSender: Sendable {
  /// Sends one message using a separate SMTP/provider envelope.
  func send(_ message: EmailMessage, envelope: EmailEnvelope) async throws -> EmailDelivery
}

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

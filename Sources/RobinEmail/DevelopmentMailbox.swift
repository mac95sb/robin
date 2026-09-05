import Foundation

/// Bounded in-process mailbox for development and tests.
public actor DevelopmentMailbox: EmailSender {
  private let capacity: Int
  private let now: @Sendable () -> Date
  private var messages: [DevelopmentEmail] = []

  /// Creates a development mailbox.
  public init(capacity: Int = 100, now: @escaping @Sendable () -> Date = Date.init) {
    precondition(capacity > 0)
    self.capacity = capacity
    self.now = now
  }

  /// Captures a message without network delivery.
  public func send(_ message: EmailMessage, envelope: EmailEnvelope) -> EmailDelivery {
    let date = now()
    messages.append(DevelopmentEmail(message: message, envelope: envelope, receivedAt: date))
    if messages.count > capacity { messages.removeFirst(messages.count - capacity) }
    return EmailDelivery(messageID: message.id, acceptedAt: date)
  }

  /// Returns captured messages in delivery order.
  public func allMessages() -> [DevelopmentEmail] { messages }

  /// Returns a complete browser-preview document for one message.
  public func preview(messageID: String) -> String? {
    messages.first { $0.message.id == messageID }?.message.html
  }

  /// Removes all captured messages.
  public func removeAll() { messages.removeAll(keepingCapacity: true) }
}

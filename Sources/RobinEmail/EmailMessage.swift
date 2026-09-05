import Foundation

/// A transactional email with HTML and plain-text alternatives.
public struct EmailMessage: Sendable {
  /// Stable message identifier: 1–64 ASCII letters, digits, hyphens, underscores or periods.
  public let id: String
  /// Visible sender header.
  public let from: EmailAddress
  /// Visible primary recipients.
  public let to: [EmailAddress]
  /// Visible carbon-copy recipients.
  public let cc: [EmailAddress]
  /// Optional reply address.
  public let replyTo: EmailAddress?
  /// Header-safe subject.
  public let subject: String
  /// Plain-text alternative.
  public let text: String
  /// Email-safe rendered HTML.
  public let html: String

  /// Creates a transactional message.
  public init(
    id: String = UUID().uuidString,
    from: EmailAddress,
    to: [EmailAddress],
    cc: [EmailAddress] = [],
    replyTo: EmailAddress? = nil,
    subject: String,
    text: String,
    html: String
  ) throws {
    guard !id.isEmpty, id.utf8.count <= 64,
      id.utf8.allSatisfy({
        (65...90).contains($0) || (97...122).contains($0)
          || (48...57).contains($0) || [45, 46, 95].contains($0)
      }),
      !to.isEmpty, !subject.contains(where: { $0 == "\r" || $0 == "\n" })
    else {
      throw EmailError.invalidHeader
    }
    self.id = id
    self.from = from
    self.to = to
    self.cc = cc
    self.replyTo = replyTo
    self.subject = subject
    self.text = text
    self.html = html
  }
}

import Foundation

/// A validated mailbox address and optional display name.
public struct EmailAddress: Equatable, Sendable {
  /// RFC mailbox value used by the SMTP envelope and headers.
  public let address: String
  /// Optional human-readable display name.
  public let name: String?

  /// Creates an address that is safe to serialize in message headers.
  public init(_ address: String, name: String? = nil) throws {
    guard !address.contains(where: { $0 == "\r" || $0 == "\n" }),
      address.split(separator: "@").count == 2,
      !address.contains(" "),
      name?.contains(where: { $0 == "\r" || $0 == "\n" }) != true
    else { throw EmailError.invalidAddress }
    self.address = address
    self.name = name
  }

  package var header: String {
    guard let name else { return address }
    let escaped = name.replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\" <\(address)>"
  }
}

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

/// A transactional email with HTML and plain-text alternatives.
public struct EmailMessage: Sendable {
  /// Stable message identifier.
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
    guard !to.isEmpty, !subject.contains(where: { $0 == "\r" || $0 == "\n" }) else {
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

/// Email validation or transport errors.
public enum EmailError: Error, Equatable, Sendable {
  /// A mailbox value could permit invalid delivery or header injection.
  case invalidAddress
  /// A required header was empty or contained a line break.
  case invalidHeader
  /// A provider returned an unexpected response.
  case unexpectedResponse(Int, String)
  /// A requested SMTP feature was not advertised by the server.
  case unsupportedFeature(String)
  /// SMTP authentication was rejected.
  case authenticationFailed
}

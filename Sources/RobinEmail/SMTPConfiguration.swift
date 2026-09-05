import NIOCore
import NIOPosix
import NIOSSL

/// Typed configuration for the built-in SMTP transport.
public struct SMTPConfiguration: Sendable {
  /// Connection security policy.
  public enum Security: Sendable {
    /// Plain SMTP, intended for loopback MTAs such as local Postfix.
    case plain
    /// Upgrade a plain connection with required STARTTLS.
    case startTLS
    /// Establish TLS before the SMTP greeting.
    case implicitTLS
  }

  /// Optional SMTP AUTH credentials.
  public struct Credentials: Sendable {
    /// Authentication identity.
    public let username: String
    /// Authentication secret.
    public let password: String

    /// Creates SMTP credentials.
    public init(username: String, password: String) {
      precondition(!username.contains("\0"))
      self.username = username
      self.password = password
    }
  }

  /// SMTP host configured by the application.
  public let host: String
  /// SMTP port.
  public let port: Int
  /// Connection security.
  public let security: Security
  /// Optional SMTP AUTH credentials.
  public let credentials: Credentials?
  /// Default public sender configured by the application.
  public let defaultSender: EmailAddress
  /// EHLO identity.
  public let clientName: String
  /// Connect and response timeout.
  public let timeout: Duration

  /// Creates SMTP settings without selecting any implicit framework endpoint.
  public init(
    host: String,
    port: Int,
    security: Security,
    credentials: Credentials? = nil,
    defaultSender: EmailAddress,
    clientName: String = "localhost",
    timeout: Duration = .seconds(10)
  ) {
    precondition(!host.isEmpty && (1...65_535).contains(port))
    precondition(!clientName.isEmpty && !clientName.contains(where: { $0 == "\r" || $0 == "\n" }))
    precondition(timeout > .zero)
    self.host = host
    self.port = port
    self.security = security
    self.credentials = credentials
    self.defaultSender = defaultSender
    self.clientName = clientName
    self.timeout = timeout
  }
}

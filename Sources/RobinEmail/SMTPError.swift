import NIOCore
import NIOPosix
import NIOSSL

/// SMTP connection and protocol framing errors.
public enum SMTPError: Error, Equatable, Sendable {
  /// The sender has shut down.
  case closed
  /// The server closed the connection before a complete response.
  case connectionClosed
  /// A server line did not contain a valid SMTP response code.
  case invalidResponse(String)
  /// The server did not respond before the configured timeout.
  case timedOut
  /// The server exceeded the bounded response line or buffer limits.
  case responseTooLarge
}

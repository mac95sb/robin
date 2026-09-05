import Foundation

/// An allowlisted email-safe component node.
public enum EmailComponent: Sendable {
  /// Escaped body text.
  case text(String, style: EmailTextStyle = .body)
  /// A safe absolute web link.
  case link(label: String, destination: URL)
  /// A vertical sequence of email components.
  case stack([EmailComponent])
  /// A deliberate line break.
  case lineBreak
}

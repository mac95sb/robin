/// Inline styles supported by the email renderer.
public enum EmailTextStyle: Sendable {
  /// Ordinary paragraph content.
  case body
  /// Primary heading content.
  case heading
  /// Secondary, visually muted content.
  case muted
}

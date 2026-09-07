/// An edge resolved by CSS's native `anchor()` function.
///
/// CSS reference: [MDN: anchor](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/anchor).
public enum AnchorEdge: String, Sendable {
  /// The top edge.
  case top
  /// The right edge.
  case right
  /// The bottom edge.
  case bottom
  /// The left edge.
  case left
  /// The center position.
  case center
}

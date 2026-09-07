/// The main-axis direction of a flex container.
///
/// CSS reference: [MDN: flex-direction](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/flex-direction).
public enum FlexDirection: String, Sendable {
  /// Places items along the inline axis in source order, following the writing direction.
  case row
  /// Reverses visual order along the inline axis; document reading order stays unchanged.
  case rowReverse = "row-reverse"
  /// Places items along the block axis in source order.
  case column
  /// Reverses visual order along the block axis; document reading order stays unchanged.
  case columnReverse = "column-reverse"
}

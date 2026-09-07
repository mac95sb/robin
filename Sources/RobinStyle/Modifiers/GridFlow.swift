/// The automatic placement direction of a grid container.
///
/// CSS reference: [MDN: grid-auto-flow](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/grid-auto-flow).
public enum GridFlow: String, Sendable {
  /// Places items by row.
  case row
  /// Places items by column.
  case column
  /// Fills earlier gaps while placing items by row; visual order can differ from reading order.
  case dense = "row dense"
}

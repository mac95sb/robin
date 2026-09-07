/// Distribution of flex items along the main axis.
///
/// CSS reference: [MDN: justify-content](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/justify-content).
public enum Justification: String, Sendable {
  /// Packs items at the main-axis start, determined by the flex direction.
  case start = "flex-start"
  /// Centers items.
  case center
  /// Packs items at the end.
  case end = "flex-end"
  /// Distributes equal space between items, with none added at the outer edges.
  case spaceBetween = "space-between"
  /// Adds equal space on either side of each item; outer gaps are half the gaps between items.
  case spaceAround = "space-around"
  /// Distributes equal space between items and container edges.
  case spaceEvenly = "space-evenly"
}

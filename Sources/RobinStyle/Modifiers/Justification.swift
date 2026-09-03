/// Distribution of flex items along the main axis.
public enum Justification: String, Sendable {
  /// Packs items at the start.
  case start = "flex-start"
  /// Centers items.
  case center
  /// Packs items at the end.
  case end = "flex-end"
  /// Distributes equal space between items.
  case spaceBetween = "space-between"
  /// Distributes equal space around items.
  case spaceAround = "space-around"
  /// Distributes equal space between items and container edges.
  case spaceEvenly = "space-evenly"
}

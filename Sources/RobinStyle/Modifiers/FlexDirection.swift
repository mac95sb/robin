/// The main-axis direction of a flex container.
public enum FlexDirection: String, Sendable {
  /// Places items horizontally in source order.
  case row
  /// Places items horizontally in reverse source order.
  case rowReverse = "row-reverse"
  /// Places items vertically in source order.
  case column
  /// Places items vertically in reverse source order.
  case columnReverse = "column-reverse"
}

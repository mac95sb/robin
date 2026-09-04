/// The automatic placement direction of a grid container.
public enum GridFlow: String, Sendable {
  /// Places items by row.
  case row
  /// Places items by column.
  case column
  /// Fills earlier gaps while placing items by row.
  case dense = "row dense"
}

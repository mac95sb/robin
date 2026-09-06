/// The marker displayed beside a list item. Inherited by list children.
public enum ListMarker: String, Sendable {
  /// No visible marker; list semantics remain unchanged.
  case none
  /// A filled circular bullet.
  case disc
  /// A decimal sequence number.
  case decimal
}

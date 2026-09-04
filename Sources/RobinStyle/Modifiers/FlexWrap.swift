/// The line-wrapping behavior of a flex container.
public enum FlexWrap: String, Sendable {
  /// Keeps all items on one line.
  case noWrap = "nowrap"
  /// Wraps items onto additional lines.
  case wrap
  /// Wraps items with the cross-axis order reversed.
  case reverse = "wrap-reverse"
}

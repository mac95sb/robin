/// A browser-native CSS containment mode.
public enum ContainerType: String, Sendable {
  /// Establishes no size-query container.
  case normal
  /// Allows queries against the inline dimension.
  case inlineSize = "inline-size"
  /// Allows queries against both dimensions.
  case size
}

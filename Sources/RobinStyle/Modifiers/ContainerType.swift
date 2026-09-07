/// A browser-native CSS containment mode.
///
/// CSS reference: [MDN: container-type](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/container-type).
public enum ContainerType: String, Sendable {
  /// Establishes no size-query container.
  case normal
  /// Allows queries against the inline dimension.
  case inlineSize = "inline-size"
  /// Allows queries against both dimensions.
  case size
}

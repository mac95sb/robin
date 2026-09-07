/// The logical alignment applied by a typography modifier.
///
/// Each case's raw value is emitted as the corresponding CSS alignment keyword.
///
/// CSS reference: [MDN: text-align](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-align).
public enum TextAlignment: String, Sendable {
  /// Aligns content with the logical start edge.
  case start

  /// Centers content within its available space.
  case center

  /// Aligns content with the logical end edge.
  case end
}

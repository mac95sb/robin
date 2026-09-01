/// The logical alignment applied by a typography modifier.
///
/// Each case's raw value is emitted as the corresponding CSS alignment keyword.
public enum TextAlignment: String, Sendable {
  /// Aligns content with the logical start edge.
  case start

  /// Centers content within its available space.
  case center

  /// Aligns content with the logical end edge.
  case end
}

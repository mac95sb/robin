/// Alignment of flex items along the cross axis.
///
/// CSS reference: [MDN: align-items](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/align-items).
public enum Alignment: String, Sendable {
  /// Stretches items across the available cross axis.
  case stretch
  /// Aligns items at the start.
  case start = "flex-start"
  /// Centers items.
  case center
  /// Aligns items at the end.
  case end = "flex-end"
  /// Aligns item text baselines.
  case baseline
}

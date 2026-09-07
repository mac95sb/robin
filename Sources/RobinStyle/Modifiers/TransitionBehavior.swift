/// A native transition behavior.
///
/// CSS reference: [MDN: transition-behavior](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-behavior).
public enum TransitionBehavior: String, Sendable {
  /// Uses normal transition interpolation rules.
  case normal
  /// Allows transitions for discrete properties.
  case allowDiscrete = "allow-discrete"
}

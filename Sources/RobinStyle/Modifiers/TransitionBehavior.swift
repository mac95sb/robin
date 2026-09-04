/// A native transition behavior.
public enum TransitionBehavior: String, Sendable {
  /// Uses normal transition interpolation rules.
  case normal
  /// Allows transitions for discrete properties.
  case allowDiscrete = "allow-discrete"
}

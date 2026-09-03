/// Whether to emit native cross-document View Transition CSS.
public enum ViewTransitionNavigation: Equatable, Sendable {
  /// Emits no cross-document view-transition CSS.
  case disabled
  /// Emits native cross-document view-transition CSS.
  case enabled
}

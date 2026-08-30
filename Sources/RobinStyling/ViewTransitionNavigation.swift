/// Whether documents in the prototype opt into cross-document View Transitions.
public enum ViewTransitionNavigation: Sendable {
  /// Uses ordinary browser navigation with no View Transition at-rule.
  case disabled

  /// Emits `@view-transition { navigation: auto }` for same-origin navigations.
  case enabled
}

/// An application's client-side navigation strategy for statically rendered sites.
///
/// `clientNavigation` only affects a Static Site application. A server-rendered application
/// always keeps server-rendered navigation and cross-document View Transitions without shipping
/// a navigation runtime.
public enum ClientNavigation: Sendable {
  /// No client navigation runtime ships. Navigating between pages performs a full document load.
  ///
  /// This is the default: a Static Site application ships no Robin client JavaScript unless
  /// `.enabled` is explicitly selected.
  case automatic

  /// A small runtime chunk intercepts same-origin navigation, fetches and swaps the requested
  /// static document, updates history, and runs a same-document View Transition.
  case enabled
}

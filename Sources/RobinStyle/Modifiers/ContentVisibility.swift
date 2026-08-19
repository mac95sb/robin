/// The CSS `content-visibility` behavior applied to an element's rendering.
///
/// Each case's raw value is its corresponding CSS keyword.
public enum ContentVisibility: String, Sendable {
  /// Skips layout and paint for off-screen content until it nears the viewport.
  case auto

  /// Renders content normally, regardless of viewport visibility.
  case visible
}

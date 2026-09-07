/// The CSS `content-visibility` behavior applied to an element's rendering.
///
/// Each case's raw value is its corresponding CSS keyword.
///
/// CSS reference: [MDN: content-visibility](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/content-visibility).
public enum ContentVisibility: String, Sendable {
  /// Skips layout and paint for off-screen content until it nears the viewport.
  case auto

  /// Renders content normally, regardless of viewport visibility.
  case visible
}

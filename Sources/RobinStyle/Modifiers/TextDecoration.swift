/// The line decoration applied by a typography modifier.
///
/// CSS reference: [MDN: text-decoration](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-decoration).
public enum TextDecoration: String, Sendable {
  /// Removes line decorations, including a link's default underline.
  case none

  /// Draws a line beneath the text.
  case underline

  /// Draws a line through the text.
  case lineThrough = "line-through"
}

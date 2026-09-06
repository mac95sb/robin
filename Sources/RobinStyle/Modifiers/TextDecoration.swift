/// The line decoration applied by a typography modifier.
public enum TextDecoration: String, Sendable {
  /// Removes line decorations, including a link's default underline.
  case none

  /// Draws a line beneath the text.
  case underline

  /// Draws a line through the text.
  case lineThrough = "line-through"
}

/// The CSS line style used to draw a border.
///
/// Each case's raw value is its corresponding CSS keyword.
///
/// CSS reference: [MDN: border-style](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/border-style).
public enum BorderStyle: String, Sendable {
  /// Draws one continuous border line.
  case solid

  /// Draws a sequence of border dashes.
  case dashed

  /// Draws a sequence of border dots.
  case dotted
}

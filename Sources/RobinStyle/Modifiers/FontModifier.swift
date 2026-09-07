import RobinHTML

extension Component {
  /// Applies a tokenized typography style as one conceptual modifier.
  ///
  /// Font properties control glyph appearance. Text alignment positions inline content within its line box; it does not align the element in its parent layout.
  ///
  /// CSS reference: [MDN: font](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/font).
  ///
  /// The typography token supplies the font family, size, and weight. Optional
  /// color and alignment declarations are included in the same conditional style
  /// group. The token values are resolved when styles are compiled.
  ///
  /// - Parameters:
  ///   - typography: The theme typography token that supplies family, size, and weight.
  ///   - color: An optional theme color token for the text color.
  ///   - decoration: An optional text decoration; omitted values preserve the existing style.
  ///   - align: An optional logical alignment emitted through the style declaration.
  ///   - lineHeight: An optional positive line height in pixels.
  ///   - letterSpacing: Optional spacing between characters in pixels; may be negative.
  ///   - condition: The cascade condition under which all generated declarations apply.
  /// - Returns: A component that appends the typography declarations to each
  ///   top-level rendered element.
  public func font(
    _ typography: TypographyToken,
    color: ColorToken? = nil,
    decoration: TextDecoration? = nil,
    align: TextAlignment? = nil,
    lineHeight: Int? = nil,
    letterSpacing: Int? = nil,
    on condition: Condition = .always
  ) -> some Component {
    var declarations = [
      styled(.fontFamily, .fontFamily(typography.rawValue), on: condition),
      styled(.fontSize, .fontSize(typography.rawValue), on: condition),
      styled(.fontWeight, .fontWeightToken(typography.rawValue), on: condition),
    ]
    if let color {
      declarations.append(styled(.color, .color(color.rawValue), on: condition))
    }
    if let decoration {
      declarations.append(styled(.textDecoration, .keyword(decoration.rawValue), on: condition))
    }
    if let align {
      declarations.append(styled(.textAlign, .keyword(align.rawValue), on: condition))
    }
    if let lineHeight {
      precondition(lineHeight > 0)
      declarations.append(styled(.lineHeight, .pixels(lineHeight), on: condition))
    }
    if let letterSpacing {
      declarations.append(styled(.letterSpacing, .keyword("\(letterSpacing)px"), on: condition))
    }
    return StyledComponent(content: self, declarations: declarations)
  }
}

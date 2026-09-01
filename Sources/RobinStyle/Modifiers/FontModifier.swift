import RobinHTML

extension Component {
  /// Applies a tokenized typography style as one conceptual modifier.
  ///
  /// The typography token supplies the font family, size, and weight. Optional
  /// color and alignment declarations are included in the same conditional style
  /// group. The token values are resolved when styles are compiled.
  ///
  /// - Parameters:
  ///   - typography: The theme typography token that supplies family, size, and weight.
  ///   - color: An optional theme color token for the text color.
  ///   - align: An optional logical alignment emitted through the style declaration.
  ///   - condition: The cascade condition under which all generated declarations apply.
  /// - Returns: A component that appends the typography declarations to each
  ///   top-level rendered element.
  public func font(
    _ typography: TypographyToken,
    color: ColorToken? = nil,
    align: TextAlignment? = nil,
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
    if let align {
      declarations.append(styled(.textAlign, .keyword(align.rawValue), on: condition))
    }
    return StyledComponent(content: self, declarations: declarations)
  }
}

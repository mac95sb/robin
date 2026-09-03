import RobinHTML

extension Component {
  /// Applies border color, width, radius, and line style as one conceptual modifier.
  ///
  /// The color and optional radius are resolved from the theme during style
  /// compilation. A negative `width` is accepted here and emitted as zero pixels.
  ///
  /// - Parameters:
  ///   - color: The theme color token for the border.
  ///   - width: The border width in pixels. Values below zero compile as `0px`.
  ///   - radius: An optional theme radius token for rounded corners.
  ///   - lineStyle: The CSS border line style.
  ///   - condition: The cascade condition under which all border declarations apply.
  /// - Returns: A component that appends the grouped border declarations to each
  ///   top-level rendered element.
  public func border(
    color: ColorToken,
    width: Int = 1,
    radius: RadiusToken? = nil,
    style lineStyle: BorderStyle = .solid,
    on condition: Condition = .always
  ) -> some Component {
    var declarations = [
      styled(.borderColor, .color(color.rawValue), on: condition),
      styled(.borderWidth, .pixels(width), on: condition),
      styled(.borderStyle, .keyword(lineStyle.rawValue), on: condition),
    ]
    if let radius {
      declarations.append(styled(.borderRadius, .radius(radius.rawValue), on: condition))
    }
    return StyledComponent(content: self, declarations: declarations)
  }
}

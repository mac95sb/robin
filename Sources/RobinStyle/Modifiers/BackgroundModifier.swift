import RobinHTML

extension Component {
  /// Applies a tokenized background color.
  ///
  /// - Parameters:
  ///   - color: The theme color token to resolve during style compilation.
  ///   - condition: The cascade condition under which the background applies.
  /// - Returns: A component that appends the background declaration to each
  ///   top-level rendered element.
  public func background(
    color: ColorToken,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.backgroundColor, .color(color.rawValue), on: condition)]
    )
  }
}

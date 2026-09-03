import RobinHTML

extension Component {
  /// Applies tokenized padding.
  ///
  /// - Parameters:
  ///   - spacing: The theme spacing token to resolve to a pixel value during
  ///     style compilation.
  ///   - condition: The cascade condition under which the padding applies.
  /// - Returns: A component that appends the padding declaration to each
  ///   top-level rendered element.
  public func padding(
    _ spacing: SpacingToken,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.padding, .spacing(spacing.rawValue), on: condition)]
    )
  }
}

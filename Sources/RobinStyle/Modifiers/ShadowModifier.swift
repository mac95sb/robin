import RobinHTML

extension Component {
  /// Applies a theme shadow token.
  ///
  /// - Parameters:
  ///   - shadow: The shadow token to resolve during style compilation.
  ///   - condition: The condition under which the declaration applies.
  public func shadow(_ shadow: ShadowToken, on condition: Condition = .always) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.boxShadow, .shadow(shadow.rawValue), on: condition)]
    )
  }
}

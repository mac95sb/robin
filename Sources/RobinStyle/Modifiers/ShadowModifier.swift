import RobinHTML

extension Component {
  /// Applies a theme shadow token.
  ///
  /// A box shadow paints a visual effect without reserving layout space. Neighboring elements do not move to accommodate it.
  ///
  /// CSS reference: [MDN: box-shadow](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/box-shadow).
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

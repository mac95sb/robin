import RobinHTML

extension Component {
  public func shadow(_ shadow: ShadowToken, on condition: Condition = .always) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.boxShadow, .shadow(shadow.rawValue), on: condition)]
    )
  }
}

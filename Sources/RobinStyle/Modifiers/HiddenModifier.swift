import RobinHTML

extension Component {
  /// Removes this component from layout and accessibility navigation under a condition.
  ///
  /// Hidden content uses display: none and takes no layout space. The browser also removes it from the accessibility tree.
  ///
  /// CSS reference: [MDN: display](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/display).
  ///
  /// Use `.hidden(on: .below(.md))` for desktop-only content, or `.hidden(on: .md)`
  /// for mobile-only content. Outside the condition, the component retains its normal layout.
  /// - Parameter condition: The condition under which the component is hidden.
  /// - Returns: A component with conditional `display: none` styling.
  public func hidden(on condition: Condition = .always) -> some Component {
    StyledComponent(
      content: self, declarations: [styled(.display, .keyword("none"), on: condition)])
  }
}

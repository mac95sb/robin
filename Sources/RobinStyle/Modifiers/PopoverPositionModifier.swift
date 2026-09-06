import RobinHTML

extension Component {
  /// Positions a native popover below its invoker, aligned to the invoker's right edge.
  /// - Parameter gap: Nonnegative space in pixels between the invoker and popover.
  /// - Returns: The popover with native CSS anchor positioning.
  public func popoverPosition(gap: Int = 8) -> some Component {
    precondition(gap >= 0)
    return StyledComponent(
      content: self,
      declarations: [
        styled(.position, .keyword("fixed"), on: .always),
        styled(.inset, .keyword("auto"), on: .always),
        styled(.margin, .pixels(0), on: .always),
        styled(.top, .keyword("calc(anchor(bottom) + \(gap)px)"), on: .always),
        styled(.right, .keyword("anchor(right)"), on: .always),
      ])
  }
}

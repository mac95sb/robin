import RobinHTML

extension Component {
  /// Applies a `content-visibility` rendering hint.
  ///
  /// `.auto` lets the browser skip layout and paint work for content that's off-screen, which
  /// can significantly improve rendering performance for long pages.
  ///
  /// - Parameters:
  ///   - visibility: The content-visibility behavior to apply.
  ///   - condition: The cascade condition under which the declaration applies.
  /// - Returns: A component that appends the content-visibility declaration to each top-level
  ///   rendered element.
  public func contentVisibility(
    _ visibility: ContentVisibility,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.contentVisibility, .keyword(visibility.rawValue), on: condition)]
    )
  }
}

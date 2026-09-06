import RobinHTML

extension Component {
  /// Selects list markers without changing the list's layout or content.
  /// - Parameters:
  ///   - marker: The marker inherited by list items, including items added later.
  ///   - condition: When this style applies.
  /// - Returns: The component with the requested list marker style.
  public func listMarker(_ marker: ListMarker, on condition: Condition = .always) -> some Component
  {
    StyledComponent(
      content: self,
      declarations: [styled(.listStyleType, .keyword(marker.rawValue), on: condition)])
  }
}

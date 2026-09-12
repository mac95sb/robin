/// Builds a list of native tabs.
@resultBuilder public enum TabsBuilder {
  /// Combines tab groups into one list.
  public static func buildBlock(_ tabs: [Tab]...) -> [Tab] {
    tabs.flatMap { $0 }
  }

  /// Includes an optional tab group when present.
  public static func buildOptional(_ tabs: [Tab]?) -> [Tab] { tabs ?? [] }

  /// Selects the first branch of a conditional tab group.
  public static func buildEither(first tabs: [Tab]) -> [Tab] { tabs }

  /// Selects the second branch of a conditional tab group.
  public static func buildEither(second tabs: [Tab]) -> [Tab] { tabs }

  /// Flattens repeated tab groups into one list.
  public static func buildArray(_ tabs: [[Tab]]) -> [Tab] {
    tabs.flatMap { $0 }
  }

  /// Converts a tab expression into a tab list.
  public static func buildExpression(_ tab: Tab) -> [Tab] { [tab] }
}

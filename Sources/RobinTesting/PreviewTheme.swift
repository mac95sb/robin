import RobinStyle

/// A named theme available in a preview dashboard.
public struct PreviewTheme: Sendable {
  /// The theme's display name.
  public let name: String
  /// The Robin theme to render.
  public let theme: Theme

  /// Creates a named preview theme.
  ///
  /// - Parameters:
  ///   - name: A nonempty display name.
  ///   - theme: The theme to render.
  public init(_ name: String, theme: Theme) {
    precondition(name.contains { !$0.isWhitespace })
    self.name = name
    self.theme = theme
  }
}

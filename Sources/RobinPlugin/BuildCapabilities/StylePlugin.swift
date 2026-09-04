import RobinStyle

/// A plugin that contributes design tokens to an application theme.
public protocol StylePlugin: Plugin {
  /// Returns a theme containing the plugin's design-token contributions.
  ///
  /// - Parameter theme: The application's current theme.
  /// - Returns: The theme for subsequent style compilation.
  func applyStyles(to theme: Theme) -> Theme
}

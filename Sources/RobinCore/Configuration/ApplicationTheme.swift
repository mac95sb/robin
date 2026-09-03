/// A theme value selected by an application without coupling RobinHTML back to RobinStyle.
public protocol ApplicationTheme: Sendable {}

/// The absence of an explicitly selected theme.
public struct DefaultApplicationTheme: ApplicationTheme {
  /// Creates the default, unconfigured theme selection.
  public init() {}
}

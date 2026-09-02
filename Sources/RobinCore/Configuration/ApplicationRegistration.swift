/// A transport-neutral route registration consumed by application composition.
public protocol ApplicationRoute: Sendable {
  /// A stable identifier used for registration and conflict diagnostics.
  var applicationRouteIdentifier: String { get }
}

/// A theme value selected by an application without coupling RobinHTML back to RobinStyle.
public protocol ApplicationTheme: Sendable {}

/// The absence of an explicitly selected theme.
public struct DefaultApplicationTheme: ApplicationTheme {
  /// Creates the default, unconfigured theme selection.
  public init() {}
}

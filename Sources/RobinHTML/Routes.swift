import RobinCore

/// A typed collection of application routes registered by an ``App``.
public protocol Routes: Sendable {
  /// The registered routes in source order.
  var routes: [any ApplicationRoute] { get }
}

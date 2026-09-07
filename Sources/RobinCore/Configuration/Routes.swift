/// A typed collection of application routes registered by an application.
public protocol Routes: Sendable {
  /// The registered routes in source order.
  var routes: [any ApplicationRoute] { get }
}

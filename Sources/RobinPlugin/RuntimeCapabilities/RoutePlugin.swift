import RobinCore

/// A plugin that contributes application routes.
public protocol RoutePlugin: Plugin {
  /// Routes registered with the application's own routes.
  var routes: [any ApplicationRoute] { get }
}

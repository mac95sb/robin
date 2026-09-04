import RobinServer

/// A plugin that contributes request middleware.
public protocol MiddlewarePlugin: Plugin {
  /// Middleware applied after Robin's required middleware and before application middleware.
  var middleware: [Middleware] { get }
}

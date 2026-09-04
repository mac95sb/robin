import RobinCore

/// A path prefix shared by a group of controller routes.
///
/// Groups can contain other groups. Robin joins their prefixes in declaration order.
///
/// ```swift
/// RouteGroup("notes") {
///   RouteGroup("admin") { DeleteNote() }
/// }
/// ```
public struct RouteGroup: ApplicationRoute {
  package let prefix: String
  package let routes: [any ApplicationRoute]

  /// Creates a route group.
  ///
  /// - Parameters:
  ///   - prefix: The path prefix applied to the group's routes.
  ///   - routes: The routes or nested groups in this group.
  public init(_ prefix: String, @RoutesBuilder routes: () -> RouteList) {
    self.prefix = prefix
    self.routes = routes().routes
  }

  /// The group prefix used while resolving its child routes.
  public var applicationRouteIdentifier: String { prefix }
}

extension RouteGroup: ApplicationRouteGroup {}

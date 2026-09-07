import RobinCore

/// A collection of related API endpoints.
///
/// Set ``prefix`` to register every endpoint beneath a shared path. The default empty prefix
/// preserves routes exactly as declared in ``body``.
public protocol Controller: ApplicationRouteGroup {
  /// The controller's endpoint declarations.
  associatedtype Body: Routes

  /// The endpoints owned by this controller.
  @RoutesBuilder var body: Body { get }
}

extension Controller {
  /// The shared path prefix for this controller's endpoints. Leave the default empty to add none.
  public var prefix: String { "" }
  /// A stable identifier used while composing the application route list.
  public var applicationRouteIdentifier: String {
    prefix.isEmpty ? String(reflecting: Self.self) : prefix
  }
  /// The controller's flattened endpoint registrations.
  public var routes: [any ApplicationRoute] { body.routes }
}

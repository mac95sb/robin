import RobinCore
import RobinHTML

/// A collection of related API endpoints.
public protocol Controller: Routes {
  /// The controller's endpoint declarations.
  associatedtype Body: Routes

  /// The endpoints owned by this controller.
  @RoutesBuilder var body: Body { get }
}

extension Controller {
  /// The controller's flattened endpoint registrations.
  public var routes: [any ApplicationRoute] { body.routes }
}

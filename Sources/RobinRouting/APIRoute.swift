import RobinCore

/// A route registration that receives automatic API-root scoping during composition.
public struct APIRoute<Value: Sendable>: ApplicationRoute, Sendable {
  public let route: Route<Value>

  public init(_ route: Route<Value>) { self.route = route }

  public var applicationRouteIdentifier: String { route.applicationRouteIdentifier }
  public var isAPIRoute: Bool { true }
}

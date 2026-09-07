import RobinCore
import RobinRouting
import RobinServer

/// Serves the unauthenticated readiness endpoint.
struct HealthController: Controller {
  /// Groups the readiness endpoint under `/api/system`.
  let prefix = "system"

  /// Registers `GET /api/system/health` without an API version prefix.
  @RoutesBuilder var body: RouteList {
    RouteGroup("health") { GET(version: nil, use: health) }
  }

  /// Returns the service readiness payload.
  ///
  /// - Returns: A response whose status is `"ok"` when the service can receive traffic.
  func health(_: Void, context _: RequestContext) -> Health {
    Health(status: "ok")
  }
}

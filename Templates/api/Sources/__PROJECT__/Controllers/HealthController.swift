import RobinHTML
import RobinRouting
import RobinServer

struct HealthController: Controller {
  @RoutesBuilder var body: RouteList { HealthEndpoint() }

  private struct HealthEndpoint: Endpoint {
    let route = "health"
    let version: Version? = nil

    /// Reports whether the service is ready to receive traffic.
    ///
    /// This public readiness route requires no authentication and accepts no request body. A
    /// successful request returns HTTP 200 with `{"status":"ok"}`. Robin's normal
    /// malformed-request and internal-error responses still apply.
    ///
    /// Readiness checks may use the deployment's standard infrastructure rate limit. The operation
    /// is safe to retry and needs no idempotency key.
    ///
    /// Example request: `GET /api/system/health`.
    func handle(_: Void, request _: EmptyRequest, context _: RequestContext) -> Health {
      Health(status: "ok")
    }
  }
}

struct Health: Encodable, Sendable {
  let status: String
}

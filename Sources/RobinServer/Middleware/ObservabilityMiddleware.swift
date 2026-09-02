import Logging
import Metrics
import Prometheus

extension Middleware {
  /// Logs request completion and records request counts and durations.
  ///
  /// Pass a metrics factory to avoid changing the process-wide Swift Metrics backend. A
  /// `PrometheusMetricsFactory` and its registry can be shared with
  /// ``prometheus(path:registry:)``.
  public static func observability(
    logger: Logger,
    metricsFactory: (any MetricsFactory)? = nil
  ) -> Self {
    Self { request, context, next in
      let started = ContinuousClock.now
      do {
        let response = try await next.respond(to: request, context: context)
        let dimensions = [
          ("method", request.method.rawValue),
          ("status", String(response.head.status.code)),
        ]
        counter(factory: metricsFactory, dimensions: dimensions).increment()
        timer(factory: metricsFactory, dimensions: dimensions).record(
          duration: started.duration(to: .now)
        )
        logger.info(
          "Request completed",
          metadata: [
            "method": "\(request.method.rawValue)",
            "path": "\(request.path)",
            "request_id": "\(context.requestID)",
            "status": "\(response.head.status.code)",
          ]
        )
        return response
      } catch {
        let dimensions = [("method", request.method.rawValue), ("status", "error")]
        counter(factory: metricsFactory, dimensions: dimensions).increment()
        timer(factory: metricsFactory, dimensions: dimensions).record(
          duration: started.duration(to: .now)
        )
        logger.error(
          "Request failed",
          metadata: [
            "method": "\(request.method.rawValue)",
            "path": "\(request.path)",
            "request_id": "\(context.requestID)",
          ]
        )
        throw error
      }
    }
  }

  /// Exposes one Prometheus collector registry in the text exposition format.
  public static func prometheus(
    path: String = "/metrics",
    registry: PrometheusCollectorRegistry
  ) -> Self {
    Self { request, context, next in
      guard request.method == .get, request.path == path else {
        return try await next.respond(to: request, context: context)
      }
      return Response(
        headers: [.contentType: "text/plain; version=0.0.4; charset=utf-8"],
        body: registry.emitToBuffer()
      )
    }
  }

  private static func counter(
    factory: (any MetricsFactory)?, dimensions: [(String, String)]
  ) -> Metrics.Counter {
    factory.map {
      Metrics.Counter(label: "robin_http_requests_total", dimensions: dimensions, factory: $0)
    } ?? Metrics.Counter(label: "robin_http_requests_total", dimensions: dimensions)
  }

  private static func timer(
    factory: (any MetricsFactory)?, dimensions: [(String, String)]
  ) -> Timer {
    factory.map { Timer(label: "robin_http_request_duration", dimensions: dimensions, factory: $0) }
      ?? Timer(label: "robin_http_request_duration", dimensions: dimensions)
  }
}

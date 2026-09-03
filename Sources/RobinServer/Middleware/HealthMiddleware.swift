import HTTPTypes

extension Middleware {
  /// Serves a dependency-aware health endpoint without application boilerplate.
  public static func health(
    path: String = "/health",
    check: @escaping @Sendable () async -> Bool = { true }
  ) -> Self {
    Self { request, context, next in
      guard request.path == path,
        request.method.rawValue.caseInsensitiveCompare("GET") == .orderedSame
      else {
        return try await next.respond(to: request, context: context)
      }
      return await check()
        ? .text("ok") : .text("unavailable", status: HTTPResponse.Status(code: 503))
    }
  }
}

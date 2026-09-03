extension Middleware {
  /// Caches read responses through provider-neutral operations.
  public static func cache(
    lookup: @escaping @Sendable (Request, RequestContext) async throws -> Response?,
    store: @escaping @Sendable (Response, Request, RequestContext) async throws -> Void
  ) -> Self {
    Self { request, context, next in
      guard ["GET", "HEAD"].contains(request.method.rawValue.uppercased()) else {
        return try await next.respond(to: request, context: context)
      }
      guard context.sessionID == nil, context.principal == nil else {
        return try await next.respond(to: request, context: context)
      }
      if let cached = try await lookup(request, context) { return cached }
      let response = try await next.respond(to: request, context: context)
      if response.head.status == .ok, response.head.headerFields[.setCookie] == nil,
        response.body.bufferedBytes != nil
      {
        try await store(response, request, context)
      }
      return response
    }
  }
}

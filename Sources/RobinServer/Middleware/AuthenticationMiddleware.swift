extension Middleware {
  /// Resolves an authenticated principal before continuing the request.
  ///
  /// - Parameter authenticate: Returns a verified principal, or `nil` for an anonymous request.
  public static func authentication(
    _ authenticate:
      @escaping @Sendable (Request, RequestContext) async throws
      -> RequestContext.Principal?
  ) -> Self {
    Self { request, context, next in
      let principal = try await authenticate(request, context)
      return try await next.respond(
        to: request,
        context: principal.map { context.replacing(principal: $0) } ?? context
      )
    }
  }
}

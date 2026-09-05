import RobinCore

extension Middleware {
  /// Loads typed services before a route or server page is evaluated.
  public static func requestServices(
    _ load: @escaping @Sendable (Request, RequestContext) async throws -> ConfigurationValues
  ) -> Self {
    Self { request, context, next in
      let services = try await load(request, context)
      return try await next.respond(
        to: request,
        context: context.replacing(services: services)
      )
    }
  }
}

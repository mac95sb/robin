import HTTPTypes

/// Application-specific rendering for otherwise generic 404 and 500 responses.
public struct ErrorResponses: Sendable {
  private let notFoundOperation: @Sendable (Request, RequestContext) -> Response
  private let internalServerErrorOperation: @Sendable (Request, RequestContext) -> Response

  /// Creates custom fallback response renderers.
  public init(
    notFound: @escaping @Sendable (Request, RequestContext) -> Response = { _, _ in
      .text("Not found", status: .notFound)
    },
    internalServerError: @escaping @Sendable (Request, RequestContext) -> Response = { _, _ in
      .text("Internal server error", status: .internalServerError)
    }
  ) {
    self.notFoundOperation = notFound
    self.internalServerErrorOperation = internalServerError
  }

  package func notFound(_ request: Request, _ context: RequestContext) -> Response {
    notFoundOperation(request, context)
  }

  package func internalServerError(_ request: Request, _ context: RequestContext) -> Response {
    internalServerErrorOperation(request, context)
  }
}

import HTTPTypes

extension Middleware {
  /// Cancels request work when its context deadline is reached.
  public static let deadline = Self { request, context, next in
    guard let deadline = context.deadline else {
      return try await next.respond(to: request, context: context)
    }
    return try await withThrowingTaskGroup(of: Response.self) { group in
      group.addTask { try await next.respond(to: request, context: context) }
      group.addTask {
        try await ContinuousClock().sleep(until: deadline)
        throw ServerError(HTTPResponse.Status(code: 504), "Request deadline exceeded")
      }
      let response = try await group.next()!
      group.cancelAll()
      return response
    }
  }
}

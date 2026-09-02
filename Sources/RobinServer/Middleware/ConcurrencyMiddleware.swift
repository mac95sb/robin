import HTTPTypes

extension Middleware {
  /// Enforces exact-path concurrent request budgets.
  public static func concurrencyLimits(_ limits: [String: Int]) -> Self {
    let limiter = ConcurrencyLimiter(limits: limits)
    return Self { request, context, next in
      guard await limiter.acquire(request.path) else {
        return .text("Request concurrency limit reached", status: HTTPResponse.Status(code: 503))
      }
      do {
        let response = try await next.respond(to: request, context: context)
        await limiter.release(request.path)
        return response
      } catch {
        await limiter.release(request.path)
        throw error
      }
    }
  }
}

private actor ConcurrencyLimiter {
  let limits: [String: Int]
  var active: [String: Int] = [:]

  init(limits: [String: Int]) {
    precondition(limits.values.allSatisfy { $0 > 0 })
    self.limits = limits
  }

  func acquire(_ path: String) -> Bool {
    guard let limit = limits[path] else { return true }
    let count = active[path, default: 0]
    guard count < limit else { return false }
    active[path] = count + 1
    return true
  }

  func release(_ path: String) {
    guard let count = active[path] else { return }
    active[path] = count == 1 ? nil : count - 1
  }
}

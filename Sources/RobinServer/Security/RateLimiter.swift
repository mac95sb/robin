package actor RateLimiter {
  package struct Decision: Sendable {
    let isAllowed: Bool
    let limit: Int
    let remaining: Int
    let resetsAfter: Duration
  }

  private struct Window: Sendable {
    var started: ContinuousClock.Instant
    var count: Int
  }

  private let limit: Int
  private let now: @Sendable () -> ContinuousClock.Instant
  private var windows: [String: Window] = [:]

  package init(
    limit: Int,
    now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now }
  ) {
    precondition(limit > 0)
    self.limit = limit
    self.now = now
  }

  package func decision(for key: String) -> Decision {
    let instant = now()
    var window = windows[key] ?? Window(started: instant, count: 0)
    if instant >= window.started.advanced(by: .seconds(60)) {
      window = Window(started: instant, count: 0)
    }
    let reset = instant.duration(to: window.started.advanced(by: .seconds(60)))
    guard window.count < limit else {
      return Decision(isAllowed: false, limit: limit, remaining: 0, resetsAfter: reset)
    }
    window.count += 1
    windows[key] = window
    return Decision(
      isAllowed: true,
      limit: limit,
      remaining: limit - window.count,
      resetsAfter: reset
    )
  }
}

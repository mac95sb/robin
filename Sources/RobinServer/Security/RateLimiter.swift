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
  private let capacity: Int
  private let now: @Sendable () -> ContinuousClock.Instant
  private var windows: [String: Window] = [:]

  package init(
    limit: Int,
    capacity: Int = 10_000,
    now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now }
  ) {
    precondition(limit > 0 && capacity > 0)
    self.limit = limit
    self.capacity = capacity
    self.now = now
  }

  package func decision(for key: String) -> Decision {
    let instant = now()
    if windows[key] == nil, windows.count >= capacity {
      // ponytail: bounded expiry scan; use an expiry queue if capacity-scale churn becomes costly.
      windows = windows.filter { instant < $0.value.started.advanced(by: .seconds(60)) }
      guard windows.count < capacity else {
        return Decision(isAllowed: false, limit: limit, remaining: 0, resetsAfter: .seconds(60))
      }
    }
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

  package var trackedKeyCount: Int { windows.count }
}

import Foundation

package actor AuthRateLimiter {
  private struct Window: Sendable {
    var startedAt: Date
    var count: Int
  }

  private let now: @Sendable () -> Date
  private let capacity = 10_000
  private var windows: [String: Window] = [:]

  package init(now: @escaping @Sendable () -> Date) { self.now = now }

  package func check(route: String, identity: String, limit: Int) throws {
    let now = now()
    let key = "\(route):\(identity)"
    var window = windows[key] ?? Window(startedAt: now, count: 0)
    if now.timeIntervalSince(window.startedAt) >= 60 {
      window = Window(startedAt: now, count: 0)
    }
    guard window.count < limit else { throw AuthError.rateLimited }
    window.count += 1
    windows[key] = window
    if windows.count > capacity {
      windows = windows.filter { now.timeIntervalSince($0.value.startedAt) < 60 }
      if windows.count > capacity,
        let oldest = windows.min(by: { $0.value.startedAt < $1.value.startedAt })
      {
        windows.removeValue(forKey: oldest.key)
      }
    }
  }
}

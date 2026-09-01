import Collections

/// Coalesces concurrent requests carrying the same idempotency key.
public actor IdempotencyStore {
  private enum Entry {
    case running([CheckedContinuation<Response, any Error>])
    case completed(Response, expiresAt: ContinuousClock.Instant)
  }

  private let capacity: Int
  private let lifetime: Duration
  private let now: @Sendable () -> ContinuousClock.Instant
  private var entries: [String: Entry] = [:]
  private var completedKeys: OrderedSet<String> = []

  /// Creates a bounded process-local idempotency store.
  ///
  /// - Parameters:
  ///   - capacity: The positive number of completed responses retained.
  ///   - lifetime: How long a completed response remains reusable.
  ///   - now: The monotonic clock source, injectable for deterministic tests.
  public init(
    capacity: Int = 1_024,
    lifetime: Duration = .seconds(86_400),
    now: @escaping @Sendable () -> ContinuousClock.Instant = { .now }
  ) {
    precondition(capacity > 0 && lifetime > .zero)
    self.capacity = capacity
    self.lifetime = lifetime
    self.now = now
  }

  /// Returns a cached response or coalesces concurrent work for the same key.
  ///
  /// Failed operations are removed and may be retried.
  ///
  /// - Parameters:
  ///   - key: The caller-defined idempotency scope.
  ///   - operation: Work performed once when no response exists.
  /// - Throws: An error produced by `operation`.
  public func response(
    for key: String,
    operation: @escaping @Sendable () async throws -> Response
  ) async throws -> Response {
    if let entry = entries[key] {
      switch entry {
      case .completed(let response, let expiresAt) where now() < expiresAt:
        return response
      case .completed:
        entries[key] = nil
      case .running(var waiters):
        return try await withCheckedThrowingContinuation { continuation in
          waiters.append(continuation)
          entries[key] = .running(waiters)
        }
      }
    }
    entries[key] = .running([])
    do {
      let value = try await operation()
      let waiters = runningWaiters(for: key)
      entries[key] = .completed(value, expiresAt: now().advanced(by: lifetime))
      completedKeys.append(key)
      if completedKeys.count > capacity {
        entries[completedKeys.removeFirst()] = nil
      }
      for waiter in waiters { waiter.resume(returning: value) }
      return value
    } catch {
      let waiters = runningWaiters(for: key)
      entries[key] = nil
      for waiter in waiters { waiter.resume(throwing: error) }
      throw error
    }
  }

  private func runningWaiters(for key: String) -> [CheckedContinuation<Response, any Error>] {
    guard case .running(let waiters) = entries[key] else { return [] }
    return waiters
  }
}

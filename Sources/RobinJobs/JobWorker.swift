import Foundation
import RobinCore

/// A type-erased, retry-safe typed job handler.
public struct AnyJobHandler: Sendable {
  package let type: String
  package let execute: @Sendable (Data, JobContext) async throws -> Void

  /// Erases a typed job handler.
  public init<Value: Job>(
    _ type: Value.Type,
    handle: @escaping @Sendable (Value, JobContext) async throws -> Void
  ) {
    self.type = type.name
    self.execute = { data, context in
      try await handle(JSONDecoder().decode(Value.self, from: data), context)
    }
  }
}

/// Worker lifecycle events suitable for logs, metrics, and traces.
public enum JobWorkerEvent: Equatable, Sendable {
  /// A job execution began.
  case started(id: String, type: String, attempt: Int)
  /// A job completed.
  case completed(id: String)
  /// A job was scheduled to retry.
  case retrying(id: String, at: Date)
  /// A job reached dead-letter state.
  case deadLettered(id: String)
}

/// Runs typed handlers against a provider-neutral queue.
public struct JobWorker: Sendable {
  /// Receives structured worker lifecycle events.
  public typealias Observer = @Sendable (JobWorkerEvent) -> Void

  private let queue: any JobQueue
  private let handlers: [String: AnyJobHandler]
  private let workerID: String
  private let tenant: TenantScope<String>
  private let services: ConfigurationValues
  private let leaseDuration: TimeInterval
  private let now: @Sendable () -> Date
  private let randomUnit: @Sendable () -> Double
  private let observer: Observer?

  /// Creates a worker with its typed handler registry and lifecycle dependencies.
  public init(
    queue: any JobQueue,
    handlers: [AnyJobHandler],
    workerID: String = UUID().uuidString,
    tenant: TenantScope<String>,
    services: ConfigurationValues = .init(),
    leaseDuration: TimeInterval = 30,
    now: @escaping @Sendable () -> Date = Date.init,
    randomUnit: @escaping @Sendable () -> Double = { Double.random(in: -1...1) },
    observer: Observer? = nil
  ) {
    precondition(leaseDuration > 0)
    self.queue = queue
    self.handlers = Dictionary(
      handlers.map { ($0.type, $0) }, uniquingKeysWith: { first, _ in first })
    self.workerID = workerID
    self.tenant = tenant
    self.services = services
    self.leaseDuration = leaseDuration
    self.now = now
    self.randomUnit = randomUnit
    self.observer = observer
  }

  /// Runs at most one due job and reports whether work was claimed.
  @discardableResult
  public func runOnce() async throws -> Bool {
    guard
      let claim = try await queue.claim(
        tenant: tenant, workerID: workerID, now: now(), leaseDuration: leaseDuration)
    else { return false }
    observer?(.started(id: claim.job.id, type: claim.job.type, attempt: claim.attempt))
    do {
      guard let handler = handlers[claim.job.type] else {
        throw JobWorkerError.missingHandler(claim.job.type)
      }
      try await handler.execute(
        claim.job.payload,
        JobContext(
          id: claim.job.id, attempt: claim.attempt, tenant: claim.job.tenant,
          services: services))
      try await queue.complete(claim)
      observer?(.completed(id: claim.job.id))
    } catch {
      let retryAt = now().addingTimeInterval(
        claim.job.retryPolicy.delay(afterAttempt: claim.attempt, randomUnit: randomUnit()))
      let disposition = try await queue.fail(
        claim, message: String(describing: error), retryAt: retryAt)
      switch disposition {
      case .retrying(let date): observer?(.retrying(id: claim.job.id, at: date))
      case .deadLettered: observer?(.deadLettered(id: claim.job.id))
      }
    }
    return true
  }

  /// Runs until cancellation, sleeping briefly when no work is due.
  public func run(pollInterval: Duration = .milliseconds(250)) async throws {
    while !Task.isCancelled {
      if try await !runOnce() { try await Task.sleep(for: pollInterval) }
    }
  }
}

/// Worker configuration errors.
public enum JobWorkerError: Error, Equatable, Sendable {
  /// No typed handler was registered for a queued job type.
  case missingHandler(String)
}

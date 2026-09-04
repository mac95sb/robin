import Foundation
import RobinCore

/// A typed payload that can be scheduled for background execution.
public protocol Job: Codable, Sendable {
  /// Stable name persisted with the encoded payload.
  static var name: String { get }
}

/// Retry limits and exponential-backoff behavior.
public struct JobRetryPolicy: Equatable, Sendable {
  /// Total permitted execution attempts, including the first attempt.
  public let maximumAttempts: Int
  /// Delay before the first retry.
  public let initialDelay: TimeInterval
  /// Upper bound for any retry delay.
  public let maximumDelay: TimeInterval
  /// Fractional random variation applied to each delay.
  public let jitter: Double

  /// Creates a bounded exponential retry policy.
  public init(
    maximumAttempts: Int = 3,
    initialDelay: TimeInterval = 1,
    maximumDelay: TimeInterval = 60,
    jitter: Double = 0.2
  ) {
    precondition(maximumAttempts > 0)
    precondition(initialDelay >= 0 && maximumDelay >= initialDelay)
    precondition((0...1).contains(jitter))
    self.maximumAttempts = maximumAttempts
    self.initialDelay = initialDelay
    self.maximumDelay = maximumDelay
    self.jitter = jitter
  }

  /// Calculates a bounded delay for a failed attempt.
  public func delay(afterAttempt attempt: Int, randomUnit: Double) -> TimeInterval {
    precondition(attempt > 0 && (-1...1).contains(randomUnit))
    let exponential = min(maximumDelay, initialDelay * pow(2, Double(attempt - 1)))
    return exponential * (1 + jitter * randomUnit)
  }
}

/// Scheduling and deduplication options for one job.
public struct JobOptions: Sendable {
  /// Earliest execution date.
  public let scheduledAt: Date
  /// Optional retry-safe deduplication identity.
  public let idempotencyKey: String?
  /// Retry behavior.
  public let retryPolicy: JobRetryPolicy

  /// Creates job options.
  public init(
    scheduledAt: Date = Date(),
    idempotencyKey: String? = nil,
    retryPolicy: JobRetryPolicy = .init()
  ) {
    self.scheduledAt = scheduledAt
    self.idempotencyKey = idempotencyKey
    self.retryPolicy = retryPolicy
  }
}

/// Verified context supplied to a job handler.
public struct JobContext: Sendable {
  /// Persistent job identifier.
  public let id: String
  /// Current one-based attempt number.
  public let attempt: Int
  /// Tenant that owns the job.
  public let tenant: TenantScope<String>
  /// Typed services shared with request handling and tests.
  public let services: ConfigurationValues
}

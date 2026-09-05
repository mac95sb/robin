import Foundation
import RobinCore

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

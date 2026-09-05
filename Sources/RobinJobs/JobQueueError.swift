import RobinCore
import RobinData

/// Durable queue errors.
public enum JobQueueError: Error, Equatable, Sendable {
  /// The built-in durable queue requires SQLite.
  case requiresSQLite
  /// A job could not be inserted or recovered by idempotency key.
  case enqueueFailed
  /// Claim leases must be positive.
  case invalidLeaseDuration
  /// Query limits must be positive.
  case invalidLimit
  /// A claim expired or belongs to another worker.
  case lostClaim
  /// Persisted job data is incomplete.
  case corruptRecord
  /// The queue has shut down.
  case closed
}

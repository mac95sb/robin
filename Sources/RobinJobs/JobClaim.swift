import Foundation
import RobinCore

/// An exclusive, expiring claim on a queued job.
public struct JobClaim: Sendable {
  /// The claimed job.
  public let job: QueuedJob
  /// Opaque token required to complete or fail this claim.
  public let token: String
  /// Current one-based attempt number.
  public let attempt: Int
  /// Time after which another worker may reclaim the job.
  public let expiresAt: Date
}

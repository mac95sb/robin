import Foundation
import RobinJobs

/// A validation-only job claim that permits one completion or failure attempt.
///
/// An abandoned or failed acknowledgement relies on the queue's durable lease expiry.
/// Noncopyability cannot replace the queue's token checks or make network acknowledgement atomic.
public struct OwnedJobClaim: ~Copyable {
  private let claim: JobClaim
  private let queue: any JobQueue

  /// Transfers a claimed job into a single-use acknowledgement handle.
  public init(_ claim: consuming JobClaim, queue: any JobQueue) {
    self.claim = claim
    self.queue = queue
  }

  /// Consumes the handle while acknowledging completion.
  public consuming func complete() async throws {
    try await queue.complete(claim)
  }

  /// Consumes the handle while recording a failed attempt.
  public consuming func fail(message: String, retryAt: Date) async throws -> JobFailureDisposition {
    try await queue.fail(claim, message: message, retryAt: retryAt)
  }
}

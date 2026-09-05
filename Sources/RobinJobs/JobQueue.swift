import Foundation
import RobinCore

/// Durable operations required by a background-job provider.
public protocol JobQueue: Sendable {
  /// Enqueues a job or returns the existing identifier for its idempotency key.
  func enqueue(_ job: QueuedJob) async throws -> String
  /// Claims the next due job for one tenant.
  func claim(
    tenant: TenantScope<String>, workerID: String, now: Date, leaseDuration: TimeInterval
  ) async throws -> JobClaim?
  /// Marks a claim complete.
  func complete(_ claim: JobClaim) async throws
  /// Records failure, rescheduling or dead-lettering the claim.
  func fail(_ claim: JobClaim, message: String, retryAt: Date) async throws
    -> JobFailureDisposition
  /// Returns dead-letter jobs for one tenant.
  func deadLetters(tenant: TenantScope<String>, limit: Int) async throws -> [QueuedJob]
  /// Releases resources and stops accepting work.
  func shutdown() async throws
}

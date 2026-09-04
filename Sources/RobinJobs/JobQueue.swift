import Foundation
import RobinCore

/// Encoded job submitted to a provider-neutral queue.
public struct QueuedJob: Sendable {
  /// Persistent identifier.
  public let id: String
  /// Stable job type name.
  public let type: String
  /// Encoded typed payload.
  public let payload: Data
  /// Tenant ownership.
  public let tenant: TenantScope<String>
  /// Earliest execution date.
  public let scheduledAt: Date
  /// Scoped idempotency identity.
  public let idempotencyKey: String?
  /// Retry policy.
  public let retryPolicy: JobRetryPolicy

  /// Creates an encoded queued job.
  public init(
    id: String,
    type: String,
    payload: Data,
    tenant: TenantScope<String>,
    scheduledAt: Date,
    idempotencyKey: String?,
    retryPolicy: JobRetryPolicy
  ) {
    self.id = id
    self.type = type
    self.payload = payload
    self.tenant = tenant
    self.scheduledAt = scheduledAt
    self.idempotencyKey = idempotencyKey
    self.retryPolicy = retryPolicy
  }
}

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

/// Result of recording a failed attempt.
public enum JobFailureDisposition: Equatable, Sendable {
  /// The job was rescheduled.
  case retrying(at: Date)
  /// The attempt limit moved the job to dead-letter state.
  case deadLettered
}

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

/// Typed enqueueing over a provider-neutral queue.
public struct JobClient: Sendable {
  private let queue: any JobQueue

  /// Creates a typed job client.
  public init(queue: any JobQueue) { self.queue = queue }

  /// Encodes and durably enqueues a job.
  @discardableResult
  public func enqueue<Value: Job>(
    _ value: Value,
    options: JobOptions = .init(),
    tenant: TenantScope<String>
  ) async throws -> String {
    let idempotencyKey = options.idempotencyKey.map {
      "\(tenant.storageIdentity):\(Value.name):\($0)"
    }
    return try await queue.enqueue(
      QueuedJob(
        id: UUID().uuidString,
        type: Value.name,
        payload: try JSONEncoder().encode(value),
        tenant: tenant,
        scheduledAt: options.scheduledAt,
        idempotencyKey: idempotencyKey,
        retryPolicy: options.retryPolicy
      ))
  }
}

extension TenantScope where ID == String {
  package var storageIdentity: String {
    switch self {
    case .none: "none"
    case .tenant(let context): "tenant:\(context.id.utf8.count):\(context.id)"
    }
  }

  package init(storageIdentity: String) {
    if storageIdentity == "none" {
      self = .none
    } else {
      let id = storageIdentity.split(separator: ":", maxSplits: 2).last.map(String.init) ?? ""
      self = .tenant(TenantContext(verified: id, source: .route))
    }
  }
}

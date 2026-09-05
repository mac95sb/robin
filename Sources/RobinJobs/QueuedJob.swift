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

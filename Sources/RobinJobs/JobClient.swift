import Foundation
import RobinCore

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

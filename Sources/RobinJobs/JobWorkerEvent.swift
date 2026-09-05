import Foundation
import RobinCore

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

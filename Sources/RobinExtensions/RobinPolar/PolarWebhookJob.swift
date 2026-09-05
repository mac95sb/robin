import Crypto
import Foundation
import HTTPTypes
import RobinCore
import RobinJobs
import RobinRouting
import RobinServer

/// Durable payload enqueued after a verified Polar webhook delivery.
public struct PolarWebhookJob: Job, Equatable, Sendable {
  /// Stable persisted job name.
  public static let name = "robin.polar.webhook"

  /// Polar's stable delivery identifier.
  public let eventID: String
  /// Polar event type, such as `subscription.updated`.
  public let eventType: String
  /// Original verified JSON bytes.
  public let body: Data

  /// Creates a verified webhook job.
  public init(eventID: String, eventType: String, body: Data) {
    self.eventID = eventID
    self.eventType = eventType
    self.body = body
  }
}

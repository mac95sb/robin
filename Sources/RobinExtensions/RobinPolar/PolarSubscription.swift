import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A Polar subscription projection used by Robin applications.
public struct PolarSubscription: Decodable, Equatable, Sendable {
  /// Subscription identifier.
  public let id: String
  /// Current provider status.
  public let status: String
  /// Subscribed product identifier.
  public let productID: String
  /// Polar customer identifier.
  public let customerID: String
  /// Whether cancellation is scheduled at the current period boundary.
  public let cancelAtPeriodEnd: Bool
  /// Current billing-period end, when supplied by Polar.
  public let currentPeriodEnd: Date?

  enum CodingKeys: String, CodingKey {
    case id, status
    case productID = "product_id"
    case customerID = "customer_id"
    case cancelAtPeriodEnd = "cancel_at_period_end"
    case currentPeriodEnd = "current_period_end"
  }
}

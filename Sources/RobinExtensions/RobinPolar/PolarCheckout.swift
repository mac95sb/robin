import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A created Polar checkout session.
public struct PolarCheckout: Decodable, Equatable, Sendable {
  /// Checkout identifier.
  public let id: String
  /// Current provider status.
  public let status: String
  /// Hosted checkout destination.
  public let url: URL
  /// Associated subscription identifier, when the checkout created one.
  public let subscriptionID: String?

  enum CodingKeys: String, CodingKey {
    case id, status, url
    case subscriptionID = "subscription_id"
  }
}

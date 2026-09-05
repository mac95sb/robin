import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Input for a Polar checkout session.
public struct PolarCheckoutRequest: Encodable, Sendable {
  /// Product identifiers offered by the checkout.
  public let products: [String]
  /// Same-origin or absolute destination after a successful checkout.
  public let successURL: URL
  /// Optional verified customer email.
  public let customerEmail: String?
  /// Stable application account identifier used to reconcile the Polar customer.
  public let externalCustomerID: String?
  /// Non-sensitive values copied to the resulting customer.
  public let customerMetadata: [String: String]

  /// Creates a checkout request.
  public init(
    products: [String],
    successURL: URL,
    customerEmail: String? = nil,
    externalCustomerID: String? = nil,
    customerMetadata: [String: String] = [:]
  ) throws {
    guard !products.isEmpty, products.allSatisfy({ !$0.isEmpty }),
      successURL.scheme == "https" || successURL.scheme == "http"
    else { throw PolarError.invalidInput }
    self.products = products
    self.successURL = successURL
    self.customerEmail = customerEmail
    self.externalCustomerID = externalCustomerID
    self.customerMetadata = customerMetadata
  }
}

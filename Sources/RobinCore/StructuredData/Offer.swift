import Foundation

extension StructuredData {
  /// A visible monetary offer attached to structured data.
  public struct Offer: Equatable, Sendable {
    /// The decimal price serialized without locale-specific formatting.
    public let price: Decimal
    /// The ISO 4217 currency code.
    public let currency: String
    /// The product or ticket availability.
    public let availability: Availability?
    /// The URL where the offer can be accepted.
    public let url: String?

    /// Creates a monetary offer.
    public init(
      price: Decimal,
      currency: String,
      availability: Availability? = nil,
      url: String? = nil
    ) {
      precondition(price >= 0)
      precondition(currency.count == 3 && currency.allSatisfy(\.isLetter))
      self.price = price
      self.currency = currency.uppercased()
      self.availability = availability
      self.url = url
    }

    /// Schema.org product availability values.
    public enum Availability: String, Equatable, Sendable {
      /// The item is available now.
      case inStock = "https://schema.org/InStock"
      /// The item is not currently available.
      case outOfStock = "https://schema.org/OutOfStock"
      /// The item can be ordered before release.
      case preorder = "https://schema.org/PreOrder"
      /// The item is available for back order.
      case backorder = "https://schema.org/BackOrder"
    }
  }
}

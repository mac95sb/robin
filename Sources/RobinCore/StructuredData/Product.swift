import Foundation

extension StructuredData {
  /// Schema-specific product facts.
  public struct Product: Equatable, Sendable {
    /// The merchant or manufacturer SKU.
    public let sku: String?
    /// The product's brand name.
    public let brand: String?
    /// The visible offers for the product.
    public let offers: [Offer]
    /// The visible aggregate rating, when available.
    public let aggregateRating: AggregateRating?

    /// Creates product facts.
    public init(
      sku: String? = nil,
      brand: String? = nil,
      offers: [Offer] = [],
      aggregateRating: AggregateRating? = nil
    ) {
      self.sku = sku
      self.brand = brand
      self.offers = offers
      self.aggregateRating = aggregateRating
    }
  }

  /// A visible aggregate rating.
  public struct AggregateRating: Equatable, Sendable {
    /// The average rating value.
    public let value: Decimal
    /// The number of ratings represented by the average.
    public let count: Int
    /// The highest value in the rating scale.
    public let best: Decimal
    /// The lowest value in the rating scale.
    public let worst: Decimal

    /// Creates an aggregate rating.
    public init(value: Decimal, count: Int, best: Decimal = 5, worst: Decimal = 1) {
      precondition(count > 0)
      precondition(best > worst && value >= worst && value <= best)
      self.value = value
      self.count = count
      self.best = best
      self.worst = worst
    }
  }
}

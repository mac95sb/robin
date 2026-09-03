extension StructuredData {
  /// Schema-specific software application facts.
  public struct SoftwareApplication: Equatable, Sendable {
    /// The operating systems that can run the application.
    public let operatingSystem: String
    /// The Schema.org application category, such as `DeveloperApplication`.
    public let category: String
    /// The current offer, when the page visibly presents one.
    public let offer: Offer?
    /// The visible aggregate rating, when available.
    public let aggregateRating: AggregateRating?

    /// Creates software application facts.
    public init(
      operatingSystem: String,
      category: String,
      offer: Offer? = nil,
      aggregateRating: AggregateRating? = nil
    ) {
      self.operatingSystem = operatingSystem
      self.category = category
      self.offer = offer
      self.aggregateRating = aggregateRating
    }
  }
}

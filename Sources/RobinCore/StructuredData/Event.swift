import Foundation

extension StructuredData {
  /// Schema-specific event facts.
  public struct Event: Equatable, Sendable {
    /// When the event starts.
    public let startDate: Date
    /// When the event ends, when known.
    public let endDate: Date?
    /// The physical venue, when attendance is in person.
    public let location: Place?
    /// The online attendance URL, when attendance is remote.
    public let onlineURL: String?
    /// The visible ticket offer, when applicable.
    public let offer: Offer?

    /// Creates event facts.
    public init(
      startDate: Date,
      endDate: Date? = nil,
      location: Place? = nil,
      onlineURL: String? = nil,
      offer: Offer? = nil
    ) {
      precondition(endDate.map { $0 >= startDate } ?? true)
      precondition(location != nil || onlineURL != nil)
      self.startDate = startDate
      self.endDate = endDate
      self.location = location
      self.onlineURL = onlineURL
      self.offer = offer
    }
  }

  /// A named physical place.
  public struct Place: Equatable, Sendable {
    /// The venue name.
    public let name: String
    /// The venue's postal address.
    public let address: PostalAddress

    /// Creates a physical place.
    public init(_ name: String, address: PostalAddress) {
      self.name = name
      self.address = address
    }
  }

  /// A postal address used by structured data.
  public struct PostalAddress: Equatable, Sendable {
    /// The street and building information.
    public let street: String
    /// The city or locality.
    public let locality: String
    /// The postal code.
    public let postalCode: String
    /// The ISO 3166 country code.
    public let country: String

    /// Creates a postal address.
    public init(street: String, locality: String, postalCode: String, country: String) {
      self.street = street
      self.locality = locality
      self.postalCode = postalCode
      self.country = country.uppercased()
    }
  }
}

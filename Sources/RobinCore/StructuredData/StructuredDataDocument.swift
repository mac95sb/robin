import Foundation

package struct StructuredDataDocument: Encodable {
  package let metadata: Metadata
  package let data: StructuredData

  package func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: SchemaKey.self)
    try container.encode("https://schema.org", forKey: "@context")
    try container.encode(data.schemaName, forKey: "@type")
    try container.encodeIfPresent(metadata.composedTitle, forKey: "name")
    try container.encodeIfPresent(metadata.description, forKey: "description")
    try container.encodeIfPresent(metadata.canonicalURL, forKey: "url")
    try container.encodeIfPresent(metadata.image?.url, forKey: "image")

    switch data {
    case .article(let article):
      try container.encode(PersonDocument(article.author), forKey: "author")
      try container.encode(article.datePublished, forKey: "datePublished")
      try container.encodeIfPresent(article.dateModified, forKey: "dateModified")
    case .breadcrumbs(let breadcrumbs):
      try container.encode(
        breadcrumbs.items.enumerated().map { BreadcrumbDocument(position: $0 + 1, item: $1) },
        forKey: "itemListElement"
      )
    case .event(let event):
      try container.encode(event.startDate, forKey: "startDate")
      try container.encodeIfPresent(event.endDate, forKey: "endDate")
      let locations = [
        event.location.map { EventLocationDocument.place(PlaceDocument($0)) },
        event.onlineURL.map { EventLocationDocument.virtual(VirtualLocationDocument(url: $0)) },
      ].compactMap(\.self)
      try container.encode(locations, forKey: "location")
      try container.encode(eventAttendanceMode(for: event), forKey: "eventAttendanceMode")
      try container.encodeIfPresent(event.offer.map(OfferDocument.init), forKey: "offers")
    case .product(let product):
      try container.encodeIfPresent(product.sku, forKey: "sku")
      try container.encodeIfPresent(product.brand.map(BrandDocument.init), forKey: "brand")
      if !product.offers.isEmpty {
        try container.encode(product.offers.map(OfferDocument.init), forKey: "offers")
      }
      try container.encodeIfPresent(
        product.aggregateRating.map(AggregateRatingDocument.init),
        forKey: "aggregateRating"
      )
    case .recipe(let recipe):
      try container.encode(recipe.ingredients, forKey: "recipeIngredient")
      try container.encode(
        recipe.instructions.map(HowToStepDocument.init),
        forKey: "recipeInstructions"
      )
      try container.encodeIfPresent(recipe.preparationTime, forKey: "prepTime")
      try container.encodeIfPresent(recipe.cookingTime, forKey: "cookTime")
      try container.encodeIfPresent(recipe.yield, forKey: "recipeYield")
      try container.encodeIfPresent(
        recipe.aggregateRating.map(AggregateRatingDocument.init),
        forKey: "aggregateRating"
      )
    case .schema(let schema):
      for (key, value) in schema.properties {
        try container.encode(SchemaValueDocument(value), forKey: key)
      }
    case .softwareApplication(let application):
      try container.encode(application.operatingSystem, forKey: "operatingSystem")
      try container.encode(application.category, forKey: "applicationCategory")
      try container.encodeIfPresent(application.offer.map(OfferDocument.init), forKey: "offers")
      try container.encodeIfPresent(
        application.aggregateRating.map(AggregateRatingDocument.init),
        forKey: "aggregateRating"
      )
    }
  }
}

private struct SchemaValueDocument: Encodable {
  let value: StructuredData.Value

  init(_ value: StructuredData.Value) { self.value = value }

  func encode(to encoder: Encoder) throws {
    switch value {
    case .string(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .number(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .integer(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .boolean(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .date(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .object(let type, let properties):
      var container = encoder.container(keyedBy: SchemaKey.self)
      try container.encode(type, forKey: "@type")
      for (key, value) in properties {
        try container.encode(SchemaValueDocument(value), forKey: key)
      }
    case .array(let values):
      var container = encoder.unkeyedContainer()
      for value in values {
        try container.encode(SchemaValueDocument(value))
      }
    }
  }
}

private func eventAttendanceMode(for event: StructuredData.Event) -> String {
  switch (event.location, event.onlineURL) {
  case (.some, .some): "https://schema.org/MixedEventAttendanceMode"
  case (.some, nil): "https://schema.org/OfflineEventAttendanceMode"
  case (nil, .some): "https://schema.org/OnlineEventAttendanceMode"
  case (nil, nil): preconditionFailure("An event requires a physical or online location")
  }
}

private struct SchemaKey: CodingKey {
  let stringValue: String
  let intValue: Int? = nil

  init(_ stringValue: String) { self.stringValue = stringValue }
  init?(stringValue: String) { self.init(stringValue) }
  init?(intValue _: Int) { nil }
}

extension KeyedEncodingContainer where Key == SchemaKey {
  fileprivate mutating func encode<T: Encodable>(_ value: T, forKey key: String) throws {
    try encode(value, forKey: SchemaKey(key))
  }

  fileprivate mutating func encodeIfPresent<T: Encodable>(_ value: T?, forKey key: String) throws {
    try encodeIfPresent(value, forKey: SchemaKey(key))
  }
}

private struct PersonDocument: Encodable {
  let type = "Person"
  let name: String
  let url: String?

  init(_ person: StructuredData.Person) {
    name = person.name
    url = person.url
  }

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case name
    case url
  }
}

private struct BreadcrumbDocument: Encodable {
  let type = "ListItem"
  let position: Int
  let name: String
  let item: String

  init(position: Int, item: StructuredData.Breadcrumb) {
    self.position = position
    name = item.name
    self.item = item.url
  }

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case position
    case name
    case item
  }
}

private struct PostalAddressDocument: Encodable {
  let type = "PostalAddress"
  let streetAddress: String
  let addressLocality: String
  let postalCode: String
  let addressCountry: String

  init(_ address: StructuredData.PostalAddress) {
    streetAddress = address.street
    addressLocality = address.locality
    postalCode = address.postalCode
    addressCountry = address.country
  }

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case streetAddress
    case addressLocality
    case postalCode
    case addressCountry
  }
}

private struct PlaceDocument: Encodable {
  let type = "Place"
  let name: String
  let address: PostalAddressDocument

  init(_ place: StructuredData.Place) {
    name = place.name
    address = PostalAddressDocument(place.address)
  }

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case name
    case address
  }
}

private enum EventLocationDocument: Encodable {
  case place(PlaceDocument)
  case virtual(VirtualLocationDocument)

  func encode(to encoder: Encoder) throws {
    switch self {
    case .place(let place): try place.encode(to: encoder)
    case .virtual(let location): try location.encode(to: encoder)
    }
  }
}

private struct VirtualLocationDocument: Encodable {
  let type = "VirtualLocation"
  let url: String

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case url
  }
}

private struct OfferDocument: Encodable {
  let type = "Offer"
  let price: Decimal
  let priceCurrency: String
  let availability: String?
  let url: String?

  init(_ offer: StructuredData.Offer) {
    price = offer.price
    priceCurrency = offer.currency
    availability = offer.availability?.rawValue
    url = offer.url
  }

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case price
    case priceCurrency
    case availability
    case url
  }
}

private struct AggregateRatingDocument: Encodable {
  let type = "AggregateRating"
  let ratingValue: Decimal
  let ratingCount: Int
  let bestRating: Decimal
  let worstRating: Decimal

  init(_ rating: StructuredData.AggregateRating) {
    ratingValue = rating.value
    ratingCount = rating.count
    bestRating = rating.best
    worstRating = rating.worst
  }

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case ratingValue
    case ratingCount
    case bestRating
    case worstRating
  }
}

private struct BrandDocument: Encodable {
  let type = "Brand"
  let name: String

  init(_ name: String) { self.name = name }

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case name
  }
}

private struct HowToStepDocument: Encodable {
  let type = "HowToStep"
  let text: String

  init(_ text: String) { self.text = text }

  enum CodingKeys: String, CodingKey {
    case type = "@type"
    case text
  }
}

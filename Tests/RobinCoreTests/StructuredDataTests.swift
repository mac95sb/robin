import Foundation
import Testing

@testable import RobinCore

@Test func everyStructuredDataKindProducesJSONLD() throws {
  let date = Date(timeIntervalSince1970: 0)
  let rating = StructuredData.AggregateRating(value: 4.5, count: 12)
  let offer = StructuredData.Offer(
    price: 9.99,
    currency: "gbp",
    availability: .inStock,
    url: "https://example.com/buy"
  )
  let address = StructuredData.PostalAddress(
    street: "1 Swift Street",
    locality: "London",
    postalCode: "SW1A 1AA",
    country: "gb"
  )
  let values: [(StructuredData, String)] = [
    (
      .article(.init(author: .init("Robin"), datePublished: date)),
      "Article"
    ),
    (
      .breadcrumbs(.init([.init("Home", url: "https://example.com")])),
      "BreadcrumbList"
    ),
    (
      .event(.init(startDate: date, location: .init("Venue", address: address), offer: offer)),
      "Event"
    ),
    (
      .product(.init(sku: "ROBIN-1", brand: "Robin", offers: [offer], aggregateRating: rating)),
      "Product"
    ),
    (
      .recipe(.init(ingredients: ["Flour"], instructions: ["Mix"], aggregateRating: rating)),
      "Recipe"
    ),
    (
      .schema(
        .init(
          type: "VideoObject",
          properties: [
            "duration": .string("PT1M"),
            "isFamilyFriendly": .boolean(true),
            "interactionStatistic": .object(
              type: "InteractionCounter",
              properties: ["userInteractionCount": .integer(12)]
            ),
          ]
        )
      ),
      "VideoObject"
    ),
    (
      .softwareApplication(
        .init(
          operatingSystem: "macOS",
          category: "DeveloperApplication",
          offer: offer,
          aggregateRating: rating
        )
      ),
      "SoftwareApplication"
    ),
  ]
  let metadata = Metadata(
    title: "Visible title",
    description: "Visible description",
    canonicalURL: "https://example.com/page"
  )

  for (value, type) in values {
    let object = try #require(
      JSONSerialization.jsonObject(with: Data(value.jsonLD(metadata: metadata).utf8))
        as? [String: Any]
    )
    #expect(object["@context"] as? String == "https://schema.org")
    #expect(object["@type"] as? String == type)
    #expect(object["name"] as? String == "Visible title")
    #expect(object["description"] as? String == "Visible description")
    #expect(object["url"] as? String == "https://example.com/page")
  }
}

@Test func structuredDataEncodesSchemaSpecificFacts() throws {
  let recipe = StructuredData.recipe(
    .init(
      ingredients: ["Flour", "Water"],
      instructions: ["Mix", "Bake"],
      preparationTime: "PT10M",
      cookingTime: "PT20M",
      yield: "4 servings"
    )
  )
  let object = try #require(
    JSONSerialization.jsonObject(with: Data(recipe.jsonLD(metadata: Metadata(title: "Bread")).utf8))
      as? [String: Any]
  )

  #expect(object["recipeIngredient"] as? [String] == ["Flour", "Water"])
  #expect(object["prepTime"] as? String == "PT10M")
  #expect((object["recipeInstructions"] as? [[String: Any]])?.count == 2)
}

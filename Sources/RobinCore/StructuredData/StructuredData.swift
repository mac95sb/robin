import Foundation

/// Schema-specific facts that supplement a page's shared metadata.
///
/// Robin supplies the name, description, canonical URL, and image from ``Metadata`` so applications
/// do not repeat those values in JSON-LD.
public enum StructuredData: Equatable, Sendable {
  /// Facts about an article or blog post.
  case article(Article)
  /// The page's position in the site's navigation hierarchy.
  case breadcrumbs(BreadcrumbList)
  /// Facts about an event and its venue.
  case event(Event)
  /// Facts about a product and its commercial availability.
  case product(Product)
  /// Facts about a recipe.
  case recipe(Recipe)
  /// Any Schema.org type expressed with typed JSON-compatible values.
  case schema(Schema)
  /// Facts about a software application.
  case softwareApplication(SoftwareApplication)

  package var schemaName: String {
    switch self {
    case .article(let article): article.kind.rawValue
    case .breadcrumbs: "BreadcrumbList"
    case .event: "Event"
    case .product: "Product"
    case .recipe: "Recipe"
    case .schema(let schema): schema.type
    case .softwareApplication: "SoftwareApplication"
    }
  }

  package func jsonLD(metadata: Metadata) throws -> String {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    let json = String(
      decoding: try encoder.encode(StructuredDataDocument(metadata: metadata, data: self)),
      as: UTF8.self
    )
    return
      json
      .replacingOccurrences(of: "&", with: "\\u0026")
      .replacingOccurrences(of: "<", with: "\\u003C")
      .replacingOccurrences(of: ">", with: "\\u003E")
  }
}

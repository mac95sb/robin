import Foundation

extension StructuredData {
  /// A Schema.org type not yet represented by a dedicated Robin value.
  public struct Schema: Equatable, Sendable {
    /// The Schema.org type name.
    public let type: String
    /// Schema-specific properties keyed by their Schema.org names.
    public let properties: [String: Value]

    /// Creates an extensible Schema.org value.
    ///
    /// Robin reserves `@context`, `@type`, `name`, `description`, `url`, and `image` because it
    /// derives those properties from ``Metadata``.
    public init(type: String, properties: [String: Value]) {
      let reserved = ["@context", "@type", "name", "description", "url", "image"]
      precondition(!type.isEmpty)
      precondition(properties.keys.allSatisfy { !reserved.contains($0) })
      self.type = type
      self.properties = properties
    }
  }

  /// A JSON-compatible value used by an extensible ``Schema``.
  public indirect enum Value: Equatable, Sendable {
    /// A text value.
    case string(String)
    /// A decimal number.
    case number(Decimal)
    /// An integer.
    case integer(Int)
    /// A Boolean value.
    case boolean(Bool)
    /// An ISO 8601 date or date-time.
    case date(Date)
    /// A nested Schema.org object.
    case object(type: String, properties: [String: Value])
    /// An ordered collection of values.
    case array([Value])
  }
}

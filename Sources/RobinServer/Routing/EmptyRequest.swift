/// The request body type for controllers that accept no JSON fields.
public struct EmptyRequest: Codable, Sendable {
  /// Creates an empty request value.
  public init() {}
}

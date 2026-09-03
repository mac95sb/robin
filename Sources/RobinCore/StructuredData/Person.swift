extension StructuredData {
  /// A person referenced by structured data.
  public struct Person: Equatable, Sendable {
    /// The person's name.
    public let name: String
    /// The person's canonical profile URL, when available.
    public let url: String?

    /// Creates a person reference.
    public init(_ name: String, url: String? = nil) {
      self.name = name
      self.url = url
    }
  }
}

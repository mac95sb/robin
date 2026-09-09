/// Reads a URL query parameter from the request currently rendering a server page.
@propertyWrapper
public struct Query: Sendable {
  private let name: String

  /// Creates a query parameter reader.
  ///
  /// - Parameter name: The query parameter name.
  public init(_ name: String) {
    precondition(!name.isEmpty)
    self.name = name
  }

  /// The decoded parameter value, or `nil` when it is absent.
  public var wrappedValue: String? {
    RequestContext.currentRequest?.queryValue(named: name)
  }
}

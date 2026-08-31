/// A deployment environment with scoped typed configuration.
public struct Environment: Sendable {
  public let name: String
  public var values: ConfigurationValues

  public init(_ name: String, values: ConfigurationValues = .init()) {
    self.name = name
    self.values = values
  }

  public func scoped(_ update: (inout ConfigurationValues) -> Void) -> Self {
    var copy = self
    update(&copy.values)
    return copy
  }
}

/// A deployment environment with scoped typed configuration.
public struct Environment: Sendable {
  /// The deployment environment name.
  public let name: String
  /// Typed configuration values active in this environment.
  public var values: ConfigurationValues

  /// Creates a named deployment environment.
  ///
  /// - Parameters:
  ///   - name: The environment name.
  ///   - values: The initial typed configuration values.
  public init(_ name: String, values: ConfigurationValues = .init()) {
    self.name = name
    self.values = values
  }

  /// Returns a copy after applying scoped configuration changes.
  ///
  /// - Parameter update: A closure that mutates the copied configuration values.
  /// - Returns: The updated environment copy.
  public func scoped(_ update: (inout ConfigurationValues) -> Void) -> Self {
    var copy = self
    update(&copy.values)
    return copy
  }
}

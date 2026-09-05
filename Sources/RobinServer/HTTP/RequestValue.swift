import RobinCore
import ServiceContextModule

/// Reads one typed value from the request currently rendering a server page.
@propertyWrapper
public struct RequestValue<Key: ConfigurationKey>: Sendable {
  /// Creates a request value for a configuration key.
  public init(_: Key.Type) {}

  /// The request-scoped value, or the key's default outside a request.
  public var wrappedValue: Key.Value { RequestContext.currentServices[Key.self] }
}

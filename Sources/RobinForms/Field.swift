/// Associates a stable form-field name with a codable value.
@propertyWrapper
public struct Field<Value: Codable & Sendable>: Sendable {
  /// The stable transport-facing field name.
  public let name: String
  /// The field's current typed value.
  public var wrappedValue: Value

  /// Creates a named form field.
  ///
  /// - Parameters:
  ///   - wrappedValue: The field's initial value.
  ///   - name: The stable transport-facing name.
  public init(wrappedValue: Value, _ name: String) {
    self.name = name
    self.wrappedValue = wrappedValue
  }

  /// The field metadata and value exposed through `$field`.
  public var projectedValue: Field<Value> { self }
}

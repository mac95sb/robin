/// Associates a stable form-field name with a codable value.
@propertyWrapper
public struct Field<Value: Codable & Sendable>: Sendable {
  public let name: String
  public var wrappedValue: Value

  public init(wrappedValue: Value, _ name: String) {
    self.name = name
    self.wrappedValue = wrappedValue
  }

  public var projectedValue: Field<Value> { self }
}

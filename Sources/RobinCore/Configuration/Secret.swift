/// A value that can be accessed explicitly but is never exposed by reflection-oriented descriptions.
public struct Secret<Value: Sendable>: Sendable {
  private let value: Value

  public init(_ value: consuming Value) { self.value = value }

  public func withValue<Result>(_ operation: (borrowing Value) throws -> Result) rethrows -> Result
  {
    try operation(value)
  }
}

extension Secret: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { "<redacted>" }
  public var debugDescription: String { description }
}

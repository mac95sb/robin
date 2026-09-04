/// A value that can be accessed explicitly but is never exposed by reflection-oriented descriptions.
public struct Secret<Value: Sendable>: Sendable {
  private let value: Value

  /// Wraps a value that must remain redacted from descriptions.
  ///
  /// - Parameter value: The secret value to consume.
  public init(_ value: consuming Value) { self.value = value }

  /// Provides temporary read access to the wrapped value.
  ///
  /// - Parameter operation: The operation allowed to borrow the secret.
  /// - Returns: The result returned by `operation`.
  /// - Throws: An error thrown by `operation`.
  public func withValue<Result>(_ operation: (borrowing Value) throws -> Result) rethrows -> Result
  {
    try operation(value)
  }
}

extension Secret: CustomStringConvertible, CustomDebugStringConvertible {
  /// A redacted description that never reveals the wrapped value.
  public var description: String { "<redacted>" }

  /// A redacted debug description that never reveals the wrapped value.
  public var debugDescription: String { description }
}

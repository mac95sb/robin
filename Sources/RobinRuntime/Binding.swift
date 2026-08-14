/// An asynchronous, codable reference to runtime state.
///
/// A binding pairs a stable identifier with read and write closures, letting
/// views and actions observe and mutate state without knowing where it lives
/// (for example, in a ``StateStore``).
public struct Binding<Value: Codable & Sendable>: Sendable {
  /// The binding's stable identifier.
  public let id: String

  private let read: @Sendable () async throws -> Value
  private let write: @Sendable (Value) async throws -> Void

  /// Creates a binding from read and write closures.
  ///
  /// - Parameters:
  ///   - id: The binding's stable identifier.
  ///   - read: A closure that produces the current value.
  ///   - write: A closure that stores a new value.
  public init(
    id: String,
    read: @escaping @Sendable () async throws -> Value,
    write: @escaping @Sendable (Value) async throws -> Void
  ) {
    self.id = id
    self.read = read
    self.write = write
  }

  /// Reads the current value.
  ///
  /// - Returns: The value produced by the binding's read closure.
  /// - Throws: Any error the read closure throws.
  public func get() async throws -> Value { try await read() }

  /// Replaces the current value.
  ///
  /// - Parameter value: The new value to store.
  /// - Throws: Any error the write closure throws.
  public func set(_ value: Value) async throws { try await write(value) }
}

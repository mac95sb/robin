/// An asynchronous, codable reference to runtime state.
public struct Binding<Value: Codable & Sendable>: Sendable {
  public let id: String
  private let read: @Sendable () async throws -> Value
  private let write: @Sendable (Value) async throws -> Void

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
  public func get() async throws -> Value { try await read() }

  /// Replaces the current value.
  public func set(_ value: Value) async throws { try await write(value) }
}

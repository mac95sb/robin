/// A named asynchronous operation exposed to the runtime.
public struct Action<Input: Codable & Sendable, Output: Codable & Sendable>: Sendable {
  public let id: String
  private let operation: @Sendable (Input) async throws -> Output

  public init(id: String, operation: @escaping @Sendable (Input) async throws -> Output) {
    self.id = id
    self.operation = operation
  }

  /// Performs the action with an input value.
  public func callAsFunction(_ input: Input) async throws -> Output { try await operation(input) }
}

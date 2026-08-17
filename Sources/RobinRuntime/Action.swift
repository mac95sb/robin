/// A named asynchronous operation exposed to the runtime.
///
/// Actions are callable values with a stable identifier, letting clients invoke
/// server-side operations by name. Call an action like a function:
///
/// ```swift
/// let createUser = Action(id: "users.create") { (input: NewUser) in ... }
/// let user = try await createUser(input)
/// ```
public struct Action<Input: Codable & Sendable, Output: Codable & Sendable>: Sendable {
  /// The action's stable identifier.
  public let id: String

  private let operation: @Sendable (Input) async throws -> Output

  /// Creates an action.
  ///
  /// - Parameters:
  ///   - id: The action's stable identifier.
  ///   - operation: The asynchronous operation the action performs.
  public init(id: String, operation: @escaping @Sendable (Input) async throws -> Output) {
    self.id = id
    self.operation = operation
  }

  /// Performs the action with an input value.
  ///
  /// - Parameter input: The action's input.
  /// - Returns: The operation's output.
  /// - Throws: Any error the operation throws.
  public func callAsFunction(_ input: Input) async throws -> Output { try await operation(input) }
}

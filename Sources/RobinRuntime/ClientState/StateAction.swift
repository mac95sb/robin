/// An ordered, atomic set of browser-local mutations, not an executable Swift closure.
/// Use `#action { count += 1 }` to describe mutations using Swift syntax.
public struct StateAction: Equatable, Sendable {
  /// The mutations evaluated in source order before any changes are published.
  @_spi(Rendering) public let mutations: [Mutation]

  /// Combines actions into one atomic operation.
  /// Later mutations read earlier results. If any result is invalid, none are applied.
  /// - Parameter actions: The actions to execute in order.
  public init(_ actions: [Self]) { mutations = actions.flatMap(\.mutations) }

  init(reference: StateReference, operation: Operation, value: String?) {
    self.mutations = [
      .init(
        reference: reference, operation: operation,
        expression: value.map(StateExpressionNode.literal))
    ]
  }

  init<Value: StateValue>(reference: StateReference, expression: StateExpression<Value>) {
    self.mutations = [.init(reference: reference, operation: .set, expression: expression.node)]
  }

  /// A single mutation in a compiled action.
  @_spi(Rendering) public struct Mutation: Equatable, Sendable {
    /// The state to update.
    public let reference: StateReference
    /// The mutation kind.
    public let operation: Operation
    /// An optional expression evaluated at event time.
    public let expression: StateExpressionNode?
  }

  /// The closed set of supported state mutations.
  @_spi(Rendering) public enum Operation: String, Sendable {
    /// Replaces the value.
    case set
    /// Reverses a Boolean.
    case toggle
  }
}

/// A typed expression evaluated from current browser-local state when an action runs.
/// The `#action` macro builds these expressions from supported Swift syntax.
public struct StateExpression<Value: StateValue>: Sendable {
  /// The renderer-facing expression tree.
  @_spi(Rendering) public let node: StateExpressionNode

  /// Creates a constant expression with the same scalar limits as `State`.
  /// - Parameter value: The value captured when the component renders.
  /// - Returns: A typed constant expression.
  public static func literal(_ value: Value) -> Self { Self(node: .literal(stateJSON(value))) }
}

/// Adds two numeric state expressions.
public func + <Value: StateValue & AdditiveArithmetic>(
  lhs: StateExpression<Value>, rhs: StateExpression<Value>
) -> StateExpression<Value> { .init(node: .add(lhs.node, rhs.node)) }

/// Subtracts two numeric state expressions.
public func - <Value: StateValue & AdditiveArithmetic>(
  lhs: StateExpression<Value>, rhs: StateExpression<Value>
) -> StateExpression<Value> { .init(node: .subtract(lhs.node, rhs.node)) }

/// Concatenates two string state expressions.
public func + (lhs: StateExpression<String>, rhs: StateExpression<String>) -> StateExpression<
  String
> {
  .init(node: .add(lhs.node, rhs.node))
}

/// Negates a Boolean state expression.
public prefix func ! (value: StateExpression<Bool>) -> StateExpression<Bool> {
  .init(node: .not(value.node))
}

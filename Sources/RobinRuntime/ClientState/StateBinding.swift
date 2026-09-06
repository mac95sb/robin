/// A typed reference to a browser-local state declaration.
public struct StateBinding<Value: StateValue>: Sendable {
  /// The renderer-facing identity and initial value.
  @_spi(Rendering) public let reference: StateReference
  /// The server-rendered initial value.
  public let initialValue: Value

  /// An expression that reads this binding's current browser value at event time.
  public var expression: StateExpression<Value> { .init(node: .state(reference)) }

  /// Describes replacing this value with an expression evaluated when the event occurs.
  /// - Parameter expression: A typed expression using current state or constants.
  /// - Returns: A browser-local state action.
  public func set(_ expression: StateExpression<Value>) -> StateAction {
    StateAction(reference: reference, expression: expression)
  }

  /// Describes replacing this state with a value.
  /// - Parameter value: A value of the same scalar type, subject to the declaration's numeric limits.
  /// - Returns: An operation to attach to a button.
  public func set(_ value: Value) -> StateAction {
    StateAction(reference: reference, operation: .set, value: stateJSON(value))
  }

  /// Describes restoring the declaration's initial value.
  /// - Returns: An operation to attach to a button.
  public func reset() -> StateAction { set(initialValue) }
}

extension StateBinding where Value == Bool {
  /// Describes reversing this Boolean value.
  /// - Returns: A Boolean toggle operation.
  public func toggle() -> StateAction {
    StateAction(reference: reference, operation: .toggle, value: nil)
  }
}

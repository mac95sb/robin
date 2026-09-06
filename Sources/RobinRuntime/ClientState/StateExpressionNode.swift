/// The closed expression vocabulary interpreted by the browser.
@_spi(Rendering) public indirect enum StateExpressionNode: Equatable, Sendable {
  /// A JSON scalar.
  case literal(String)
  /// A live state reference.
  case state(StateReference)
  /// Addition or string concatenation.
  case add(StateExpressionNode, StateExpressionNode)
  /// Numeric subtraction.
  case subtract(StateExpressionNode, StateExpressionNode)
  /// Boolean negation.
  case not(StateExpressionNode)
}

/// A deterministic CSS compiler integrity error.
public enum StyleCompilerError: Error, Equatable, Sendable {
  /// Two distinct resolved signatures produced the same versioned selector.
  case selectorCollision(String)
}

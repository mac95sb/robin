/// A custom color-token registration error.
public enum ColorTokenSetError: Error, Equatable, Sendable {
  /// One or more cases in a typed token set have no registered color.
  case missingTokens([String])
}

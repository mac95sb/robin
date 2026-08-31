/// An invalid application composition detected while inferring ``ApplicationMode``.
public enum ApplicationCompositionError: Error, Equatable, Sendable {
  /// The application registered neither views nor controllers, so no rendering
  /// strategy can be inferred.
  case empty
}

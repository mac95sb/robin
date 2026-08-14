/// An invalid application composition detected while inferring ``ApplicationMode``.
enum ApplicationCompositionError: Error {
  /// The application registered neither views nor controllers, so no rendering
  /// strategy can be inferred.
  case empty
}

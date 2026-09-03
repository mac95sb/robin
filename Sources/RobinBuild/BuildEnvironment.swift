/// The validation policy applied while producing artifacts.
public enum BuildEnvironment: Equatable, Sendable {
  /// Allows unpinned remote inputs for local iteration.
  case development
  /// Requires every remote input to have a verified content digest.
  case production
}

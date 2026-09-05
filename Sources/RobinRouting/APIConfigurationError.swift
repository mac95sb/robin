/// An invalid API root or version configuration.
public enum APIConfigurationError: Error, Equatable, Sendable {
  /// The supplied API root is empty or contains traversal segments.
  case invalidRoot(String)
  /// The supplied API version is not positive.
  case invalidVersion(Int)
  /// API versioning was configured more than once in one route path.
  case nestedVersion
}

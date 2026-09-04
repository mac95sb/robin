/// An invalid API root or version configuration.
public enum APIConfigurationError: Error, Equatable, Sendable {
  /// The supplied API root is empty or contains traversal segments.
  case invalidRoot(String)
  /// The supplied API version is not positive.
  case invalidVersion(Int)
  /// API versioning was configured more than once in one route path.
  case nestedVersion
}

/// The root path shared by application API routes.
public struct APIConfiguration: Equatable, Sendable {
  /// The conventional `/api` root.
  public static let `default` = try! APIConfiguration(root: "/api")
  /// The normalized API root.
  public let root: APIPath

  /// Creates an API configuration.
  ///
  /// - Parameter root: The slash-delimited API root.
  /// - Throws: ``APIConfigurationError/invalidRoot(_:)`` for an invalid root.
  public init(root: String) throws { self.root = try APIPath(root) }
}

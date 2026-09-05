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

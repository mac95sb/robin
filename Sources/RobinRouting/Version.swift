/// A positive externally visible API version.
public struct Version: Equatable, Sendable {
  /// The default first public API version.
  public static let `default` = try! Version(1)

  /// The lifecycle state advertised for an API version.
  public enum Status: Equatable, Sendable {
    /// The version is current and supported.
    case current
    /// The version remains available but should not be selected for new integrations.
    case deprecated
    /// The version is scheduled for removal at the supplied date or release label.
    case sunset(String)
  }

  /// The positive version number serialized after `v`.
  public let number: Int
  /// The version's lifecycle state.
  public let status: Status

  /// Creates a positive API version.
  ///
  /// - Parameters:
  ///   - number: The positive external version number.
  ///   - status: The version's lifecycle state.
  /// - Throws: ``APIConfigurationError/invalidVersion(_:)`` when `number` is not positive.
  public init(_ number: Int, status: Status = .current) throws {
    guard number > 0 else { throw APIConfigurationError.invalidVersion(number) }
    self.number = number
    self.status = status
  }

  /// Prefixes a relative route with the API root and version.
  ///
  /// - Parameters:
  ///   - relativePath: The API-root-relative route path.
  ///   - api: The application API-root configuration.
  /// - Returns: The normalized, versioned path.
  public func path(relativePath: String, api: APIConfiguration = .default) -> String {
    let relative = relativePath.drop(while: { $0 == "/" })
    return "\(api.root.value)/v\(number)" + (relative.isEmpty ? "" : "/\(relative)")
  }
}

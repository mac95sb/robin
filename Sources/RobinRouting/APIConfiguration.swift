/// A normalized API root. Controllers declare paths relative to this value.
public struct APIPath: Equatable, Sendable {
  /// The normalized root-relative path beginning with `/`.
  public let value: String

  /// Creates a normalized API root.
  ///
  /// - Parameter value: A slash-delimited API root.
  /// - Throws: ``APIConfigurationError/invalidRoot(_:)`` when the path is empty or traverses.
  public init(_ value: String) throws {
    let segments = value.split(separator: "/", omittingEmptySubsequences: true)
    guard !segments.isEmpty, !segments.contains("."), !segments.contains("..") else {
      throw APIConfigurationError.invalidRoot(value)
    }
    self.value = "/" + segments.joined(separator: "/")
  }
}

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

/// A positive externally visible API version.
public struct Version: Equatable, Sendable {
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

/// A normalized API root. Controllers declare paths relative to this value.
public struct APIPath: Equatable, Sendable {
  public let value: String

  public init(_ value: String) throws {
    let segments = value.split(separator: "/", omittingEmptySubsequences: true)
    guard !segments.isEmpty, !segments.contains("."), !segments.contains("..") else {
      throw APIConfigurationError.invalidRoot(value)
    }
    self.value = "/" + segments.joined(separator: "/")
  }
}

public enum APIConfigurationError: Error, Equatable, Sendable {
  case invalidRoot(String)
  case invalidVersion(Int)
  case nestedVersion
}

public struct APIConfiguration: Equatable, Sendable {
  public static let `default` = try! APIConfiguration(root: "/api")
  public let root: APIPath

  public init(root: String) throws { self.root = try APIPath(root) }
}

public struct Version: Equatable, Sendable {
  public enum Status: Equatable, Sendable {
    case current, deprecated
    case sunset(String)
  }

  public let number: Int
  public let status: Status

  public init(_ number: Int, status: Status = .current) throws {
    guard number > 0 else { throw APIConfigurationError.invalidVersion(number) }
    self.number = number
    self.status = status
  }

  public func path(relativePath: String, api: APIConfiguration = .default) -> String {
    let relative = relativePath.drop(while: { $0 == "/" })
    return "\(api.root.value)/v\(number)" + (relative.isEmpty ? "" : "/\(relative)")
  }
}

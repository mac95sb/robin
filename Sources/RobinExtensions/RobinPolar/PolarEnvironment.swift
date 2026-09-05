import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// The Polar API environment used by a client.
public enum PolarEnvironment: Sendable {
  /// Polar's production API.
  case production
  /// Polar's sandbox API.
  case sandbox
  /// A compatible custom API root, including the `/v1` path.
  case custom(URL)

  var url: URL {
    switch self {
    case .production: URL(string: "https://api.polar.sh/v1")!
    case .sandbox: URL(string: "https://sandbox-api.polar.sh/v1")!
    case .custom(let url): url
    }
  }
}

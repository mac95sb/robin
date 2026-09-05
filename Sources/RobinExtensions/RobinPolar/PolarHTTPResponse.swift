import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A transport response used by ``PolarClient``.
public struct PolarHTTPResponse: Sendable {
  /// HTTP status code returned by Polar.
  public let statusCode: Int
  /// Complete response body.
  public let body: Data

  /// Creates a transport response.
  public init(statusCode: Int, body: Data) {
    self.statusCode = statusCode
    self.body = body
  }
}

import Crypto
import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A transport response used by ``OIDCClient``.
public struct OIDCHTTPResponse: Sendable {
  /// Provider HTTP status code.
  public let statusCode: Int
  /// Complete provider response body.
  public let body: Data

  /// Creates a transport response.
  public init(statusCode: Int, body: Data) {
    self.statusCode = statusCode
    self.body = body
  }
}

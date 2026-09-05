import Crypto
import Foundation
import NIOCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
#if canImport(FoundationXML)
  import FoundationXML
#endif

/// Credentials and endpoint settings for an S3-compatible object store.
public struct S3Configuration: Sendable {
  /// Service endpoint, including its HTTP or HTTPS scheme.
  public let endpoint: URL
  /// Bucket name.
  public let bucket: String
  /// Signing region.
  public let region: String
  /// Access-key identity.
  public let accessKeyID: String
  /// Secret signing key.
  public let secretAccessKey: String
  /// Optional session token.
  public let sessionToken: String?
  /// Namespace reserved for Robin objects in the bucket.
  public let keyPrefix: String
  /// Whether the endpoint uses path-style bucket URLs.
  public let usesPathStyle: Bool
  /// Network timeout.
  public let timeout: TimeInterval

  /// Creates validated S3-compatible settings.
  public init(
    endpoint: URL,
    bucket: String,
    region: String,
    accessKeyID: String,
    secretAccessKey: String,
    sessionToken: String? = nil,
    keyPrefix: String = "robin",
    usesPathStyle: Bool = true,
    timeout: TimeInterval = 30
  ) throws {
    guard let scheme = endpoint.scheme?.lowercased(), scheme == "https" || scheme == "http",
      endpoint.host != nil,
      !bucket.isEmpty, !region.isEmpty, !accessKeyID.isEmpty, !secretAccessKey.isEmpty,
      !keyPrefix.isEmpty, !keyPrefix.hasPrefix("/"), !keyPrefix.hasSuffix("/"),
      !keyPrefix.split(separator: "/").contains(".."), timeout > 0
    else { throw StorageError.invalidRoot }
    self.endpoint = endpoint
    self.bucket = bucket
    self.region = region
    self.accessKeyID = accessKeyID
    self.secretAccessKey = secretAccessKey
    self.sessionToken = sessionToken
    self.keyPrefix = keyPrefix
    self.usesPathStyle = usesPathStyle
    self.timeout = timeout
  }
}

import Foundation
import NIOCore

/// Controls when a forwarded client address may influence abuse protection.
public struct TrustedProxyPolicy: Equatable, Sendable {
  /// Exact transport peer addresses allowed to supply a forwarded address.
  public let trustedAddresses: Set<String>

  /// Creates an exact-address proxy allowlist.
  ///
  /// - Parameter trustedAddresses: Transport peer addresses allowed to set `X-Forwarded-For`.
  public init(trustedAddresses: Set<String> = []) {
    self.trustedAddresses = Set(trustedAddresses.compactMap(Self.normalized))
  }

  /// Resolves the abuse-protection identity without trusting arbitrary forwarding headers.
  ///
  /// - Parameters:
  ///   - remoteAddress: The transport peer address.
  ///   - forwardedFor: The untrusted `X-Forwarded-For` header value.
  /// - Returns: The first untrusted address walking from the peer toward the client,
  ///   or `"unknown"` when no peer address is available.
  public func clientAddress(remoteAddress: String?, forwardedFor: String?) -> String {
    guard let remoteAddress, var current = Self.normalized(remoteAddress), let forwardedFor
    else { return remoteAddress ?? "unknown" }
    for hop in forwardedFor.split(separator: ",", omittingEmptySubsequences: false).reversed() {
      guard trustedAddresses.contains(current) else { break }
      guard let candidate = Self.normalized(hop.trimmingCharacters(in: .whitespaces)) else {
        return Self.normalized(remoteAddress) ?? remoteAddress
      }
      current = candidate
    }
    return current
  }

  private static func normalized(_ address: String) -> String? {
    try? SocketAddress(ipAddress: address, port: 0).ipAddress
  }
}

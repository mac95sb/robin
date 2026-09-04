import Foundation

/// Controls when a forwarded client address may influence abuse protection.
public struct TrustedProxyPolicy: Equatable, Sendable {
  /// Exact transport peer addresses allowed to supply a forwarded address.
  public let trustedAddresses: Set<String>

  /// Creates an exact-address proxy allowlist.
  ///
  /// - Parameter trustedAddresses: Transport peer addresses allowed to set `X-Forwarded-For`.
  public init(trustedAddresses: Set<String> = []) { self.trustedAddresses = trustedAddresses }

  /// Resolves the abuse-protection identity without trusting arbitrary forwarding headers.
  ///
  /// - Parameters:
  ///   - remoteAddress: The transport peer address.
  ///   - forwardedFor: The untrusted `X-Forwarded-For` header value.
  /// - Returns: The first valid forwarded address for a trusted peer, the peer address otherwise,
  ///   or `"unknown"` when no peer address is available.
  public func clientAddress(remoteAddress: String?, forwardedFor: String?) -> String {
    guard let remoteAddress, trustedAddresses.contains(remoteAddress), let forwardedFor,
      let first = forwardedFor.split(separator: ",").first
    else { return remoteAddress ?? "unknown" }
    let candidate = first.trimmingCharacters(in: .whitespaces)
    let valid =
      !candidate.isEmpty
      && candidate.allSatisfy { $0.isNumber || "abcdefABCDEF.:".contains($0) }
    return valid ? candidate : remoteAddress
  }
}

import Foundation
import RobinCore
import RobinEmail
import Testing

@testable import RobinAuth

@Suite("Authentication configuration")
struct ConfigurationTests {
  @Test func rejectsUnsafeConfigurationAndUntrustedForwarding() throws {
    #expect(throws: AuthError.invalidConfiguration) {
      try PasskeyConfiguration(
        relyingPartyID: "other.example.com",
        relyingPartyName: "Example",
        origin: #require(URL(string: "https://login.example.com")))
    }
    #expect(
      TrustedProxyPolicy().clientAddress(
        remoteAddress: "proxy", forwardedFor: "203.0.113.9") == "proxy")
    #expect(
      TrustedProxyPolicy(trustedAddresses: ["127.0.0.1"])
        .clientAddress(remoteAddress: "127.0.0.1", forwardedFor: "203.0.113.9, 198.51.100.4")
        == "198.51.100.4")
    #expect(throws: AuthError.invalidConfiguration) {
      try PasskeyConfiguration(
        relyingPartyID: "example.com",
        relyingPartyName: "Example",
        origin: #require(URL(string: "https://example.com")),
        challengeLifetime: .infinity)
    }
    #expect(throws: AuthError.invalidConfiguration) {
      try MagicLinkConfiguration(
        applicationName: "Example",
        callbackURL: #require(URL(string: "https://example.com/auth/magic")),
        sender: EmailAddress("auth@example.com"),
        signingKey: Secret(Data(repeating: 0, count: 31)))
    }
  }

  @Test func proxyChainsStopAtTheFirstUntrustedHop() {
    let policy = TrustedProxyPolicy(trustedAddresses: ["127.0.0.1", "::1"])
    #expect(
      policy.clientAddress(remoteAddress: "127.0.0.1", forwardedFor: "203.0.113.9, ::1")
        == "203.0.113.9")
    #expect(
      policy.clientAddress(remoteAddress: "198.51.100.4", forwardedFor: "203.0.113.9")
        == "198.51.100.4")
    for header in ["203.0.113.9,", "203.0.113.9, bad", "203.0.113.9, 127.0.0.1:80"] {
      #expect(policy.clientAddress(remoteAddress: "127.0.0.1", forwardedFor: header) == "127.0.0.1")
    }
    #expect(
      policy.clientAddress(remoteAddress: "::1", forwardedFor: "2001:db8::1") == "2001:db8::1")
  }
}

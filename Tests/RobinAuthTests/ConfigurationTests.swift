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
      TrustedProxyPolicy(trustedAddresses: ["proxy"])
        .clientAddress(remoteAddress: "proxy", forwardedFor: "203.0.113.9, 198.51.100.4")
        == "203.0.113.9")
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
}

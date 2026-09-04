import Foundation
import RobinData
import Testing
import WebAuthn

@testable import RobinAuth

@Suite("Passkey ceremonies and credentials")
struct PasskeyTests {
  @Test func ceremoniesUseSwiftWebAuthnExpireCancelAndThrottle() async throws {
    let date = MutableDate(Date(timeIntervalSince1970: 4_000))
    let testDatabase = try await TestDatabase.sqlite()
    let keyValues = try await DatabaseKeyValueStore(database: testDatabase.database, now: date.get)
    let store = AuthStore(keyValues)
    let sessions = AuthSessionManager(store: store, now: date.get)
    let service = PasskeyService(
      configuration: try configuration(lifetime: 10),
      store: store,
      sessions: sessions,
      now: date.get,
      attemptLimit: 2)
    let account = try Account(id: "account", name: "Person", createdAt: date.get())

    let registration = try await service.beginRegistration(for: account, clientIdentity: "client")
    #expect(registration.options.relyingParty.id == "example.com")
    #expect(registration.options.user.id == Array("account".utf8))
    try await service.cancel(ceremonyID: registration.id)
    await #expect(throws: AuthError.invalidCeremony) {
      try await service.finishRegistration(
        ceremonyID: registration.id,
        credential: malformedRegistrationCredential())
    }

    let authentication = try await service.beginAuthentication(clientIdentity: "client")
    #expect(authentication.options.relyingPartyID == "example.com")
    _ = try await service.beginAuthentication(clientIdentity: "client")
    await #expect(throws: AuthError.rateLimited) {
      try await service.beginAuthentication(clientIdentity: "client")
    }
    date.value = date.value.addingTimeInterval(11)
    await #expect(throws: AuthError.invalidCeremony) {
      try await service.finishAuthentication(
        ceremonyID: authentication.id,
        credential: malformedAuthenticationCredential())
    }
    try await testDatabase.remove()
  }

  @Test func credentialChangesRequireRecentAuthenticationAndRecovery() async throws {
    let date = MutableDate(Date(timeIntervalSince1970: 5_000))
    let testDatabase = try await TestDatabase.sqlite()
    let keyValues = try await DatabaseKeyValueStore(database: testDatabase.database, now: date.get)
    let store = AuthStore(keyValues)
    let sessions = AuthSessionManager(store: store, now: date.get)
    let service = PasskeyService(
      configuration: try configuration(),
      store: store,
      sessions: sessions,
      now: date.get)
    let account = try Account(id: "account", name: "Person", createdAt: date.get())
    try await store.save(account)
    let credential = PasskeyCredential(
      id: "credential",
      accountID: account.id,
      publicKey: Data([1]),
      signCount: 0,
      backupEligible: false,
      isBackedUp: false,
      name: "Phone",
      createdAt: date.get(),
      lastUsedAt: nil)
    #expect(try await store.saveCredential(credential))
    let session = try await sessions.create(for: account.id)

    try await service.renameCredential(
      credential.id,
      to: "Laptop",
      accountID: account.id,
      authenticatedBy: session.value)
    #expect(
      try await service.credentials(for: account.id, authenticatedBy: session.value).first?.name
        == "Laptop")
    await #expect(throws: AuthError.recoveryUnavailable) {
      try await service.removeCredential(
        credential.id,
        accountID: account.id,
        authenticatedBy: session.value)
    }
    try await testDatabase.remove()
  }

  private func configuration(lifetime: TimeInterval = 300) throws -> PasskeyConfiguration {
    try PasskeyConfiguration(
      relyingPartyID: "example.com",
      relyingPartyName: "Example",
      origin: #require(URL(string: "https://example.com")),
      challengeLifetime: lifetime)
  }

  private func malformedRegistrationCredential() throws -> RegistrationCredential {
    try JSONDecoder().decode(
      RegistrationCredential.self,
      from: Data(
        #"{"id":"AA","type":"public-key","rawId":"AA","response":{"clientDataJSON":"AA","attestationObject":"AA"}}"#
          .utf8))
  }

  private func malformedAuthenticationCredential() throws -> AuthenticationCredential {
    try JSONDecoder().decode(
      AuthenticationCredential.self,
      from: Data(
        #"{"id":"AA","type":"public-key","rawId":"AA","response":{"clientDataJSON":"AA","authenticatorData":"AA","signature":"AA"}}"#
          .utf8))
  }
}

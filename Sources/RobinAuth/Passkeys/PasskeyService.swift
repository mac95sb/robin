import Foundation
import WebAuthn

/// Durable passkey registration, authentication, and credential management.
public struct PasskeyService: Sendable {
  private let configuration: PasskeyConfiguration
  private let recoveryPolicy: RecoveryPolicy
  private let store: AuthStore
  private let sessions: AuthSessionManager
  private let now: @Sendable () -> Date
  private let limiter: AuthRateLimiter
  private let attemptLimit: Int
  package var origin: String {
    configuration.origin.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
  }
  private let audit: @Sendable (AuthAuditEvent) -> Void

  /// Creates the built-in passkey service.
  ///
  /// - Parameters:
  ///   - configuration: Validated relying-party and origin settings.
  ///   - recoveryPolicy: The method required before removing an account's final passkey.
  ///   - store: Durable account, credential, and challenge storage.
  ///   - sessions: The session issuer used after successful authentication.
  ///   - now: The wall-clock source. Inject a deterministic closure in tests.
  ///   - attemptLimit: The maximum ceremony starts per client identity in one minute.
  ///   - audit: A synchronous receiver for redacted authentication events.
  /// - Precondition: `attemptLimit` is positive.
  public init(
    configuration: PasskeyConfiguration,
    recoveryPolicy: RecoveryPolicy = .passkeysOnly,
    store: AuthStore,
    sessions: AuthSessionManager,
    now: @escaping @Sendable () -> Date = Date.init,
    attemptLimit: Int = 20,
    audit: @escaping @Sendable (AuthAuditEvent) -> Void = { _ in }
  ) {
    self.configuration = configuration
    self.recoveryPolicy = recoveryPolicy
    self.store = store
    self.sessions = sessions
    precondition(attemptLimit > 0)
    self.now = now
    self.limiter = AuthRateLimiter(now: now)
    self.attemptLimit = attemptLimit
    self.audit = audit
  }

  /// Starts registration for a new account or an authenticated existing account.
  ///
  /// - Parameters:
  ///   - account: The new or existing account that will own the credential.
  ///   - sessionToken: A recently authenticated session required for an existing account.
  ///   - clientIdentity: A nonempty, trusted rate-limit identity such as the resolved client IP.
  /// - Returns: Browser registration options and their opaque server-side ceremony identifier.
  /// - Throws: ``AuthError`` for invalid input, rate limiting, or insufficient recent
  ///   authentication, or an error from durable storage.
  public func beginRegistration(
    for account: Account,
    authenticatedBy sessionToken: String? = nil,
    clientIdentity: String
  ) async throws -> PasskeyRegistrationCeremony {
    guard !clientIdentity.isEmpty else { throw AuthError.invalidInput }
    try await limiter.check(
      route: "passkey.registration", identity: clientIdentity, limit: attemptLimit)
    let userID = Array(account.id.utf8)
    guard !userID.isEmpty, userID.count <= 64 else { throw AuthError.invalidInput }
    if try await store.account(id: account.id, at: now()) != nil {
      guard let sessionToken else { throw AuthError.recentAuthenticationRequired }
      try await sessions.requireRecent(sessionToken, for: account.id)
    }
    let options = configuration.manager.beginRegistration(
      user: .init(id: userID, name: account.name, displayName: account.name),
      timeout: .milliseconds(Int64(configuration.challengeLifetime * 1_000)))
    let expiresAt = now().addingTimeInterval(configuration.challengeLifetime)
    let id = try await store.storeChallenge(
      StoredChallenge(
        purpose: .registration,
        account: account,
        challenge: Data(options.challenge),
        expiresAt: expiresAt))
    return PasskeyRegistrationCeremony(id: id, options: options)
  }

  /// Completes registration and persists the verified credential.
  ///
  /// The ceremony is consumed before verification, so a failed response cannot be replayed.
  ///
  /// - Parameters:
  ///   - ceremonyID: The opaque identifier returned by ``beginRegistration(for:authenticatedBy:clientIdentity:)``.
  ///   - response: The credential returned by `navigator.credentials.create()`.
  ///   - credentialName: A nonempty label shown during credential management.
  /// - Returns: The persisted credential.
  /// - Throws: ``AuthError/invalidCeremony`` or ``AuthError/invalidCredential`` when validation
  ///   fails, or an error from durable storage.
  public func finishRegistration(
    ceremonyID: String,
    credential response: RegistrationCredential,
    credentialName: String = "Passkey"
  ) async throws -> PasskeyCredential {
    guard !credentialName.isEmpty,
      let challenge = try await store.consumeChallenge(ceremonyID, at: now()),
      challenge.purpose == .registration,
      let account = challenge.account
    else { throw AuthError.invalidCeremony }
    let credential: Credential
    do {
      credential = try await configuration.manager.finishRegistration(
        challenge: Array(challenge.challenge),
        credentialCreationData: response,
        requireUserVerification: configuration.requireUserVerification
      ) { id in
        try await store.credential(id: id, at: now()) == nil
      }
    } catch {
      throw AuthError.invalidCredential
    }
    let stored = PasskeyCredential(
      id: response.id.asString(),
      accountID: account.id,
      publicKey: Data(credential.publicKey),
      signCount: credential.signCount,
      backupEligible: credential.backupEligible,
      isBackedUp: credential.isBackedUp,
      name: credentialName,
      createdAt: now(),
      lastUsedAt: nil)
    guard try await store.saveCredential(stored) else { throw AuthError.invalidCredential }
    try await store.save(account, at: now())
    audit(.init(kind: .passkeyRegistered, accountID: account.id, occurredAt: now()))
    return stored
  }

  /// Starts account-discoverable authentication without revealing account existence.
  ///
  /// - Parameter clientIdentity: A nonempty, trusted rate-limit identity such as the resolved
  ///   client IP.
  /// - Returns: Browser authentication options and their opaque server-side ceremony identifier.
  /// - Throws: ``AuthError/invalidInput`` or ``AuthError/rateLimited``, or a storage error.
  public func beginAuthentication(clientIdentity: String) async throws
    -> PasskeyAuthenticationCeremony
  {
    guard !clientIdentity.isEmpty else { throw AuthError.invalidInput }
    try await limiter.check(
      route: "passkey.authentication", identity: clientIdentity, limit: attemptLimit)
    let options = configuration.manager.beginAuthentication(
      timeout: .milliseconds(Int64(configuration.challengeLifetime * 1_000)),
      allowCredentials: nil,
      userVerification: configuration.requireUserVerification ? .required : .preferred)
    let id = try await store.storeChallenge(
      StoredChallenge(
        purpose: .authentication,
        account: nil,
        challenge: Data(options.challenge),
        expiresAt: now().addingTimeInterval(configuration.challengeLifetime)))
    return PasskeyAuthenticationCeremony(id: id, options: options)
  }

  /// Verifies an assertion, advances its counter, and creates a session.
  ///
  /// The ceremony is consumed before verification, so a failed assertion cannot be replayed.
  ///
  /// - Parameters:
  ///   - ceremonyID: The opaque identifier returned by ``beginAuthentication(clientIdentity:)``.
  ///   - response: The assertion returned by `navigator.credentials.get()`.
  /// - Returns: A newly issued session bearer token.
  /// - Throws: ``AuthError/invalidCeremony`` or ``AuthError/invalidCredential`` when validation
  ///   fails, or an error from durable storage.
  public func finishAuthentication(
    ceremonyID: String,
    credential response: AuthenticationCredential
  ) async throws -> SessionToken {
    guard
      let challenge = try await store.consumeChallenge(ceremonyID, at: now()),
      challenge.purpose == .authentication,
      let credential = try await store.credential(id: response.id.asString(), at: now())
    else { throw AuthError.invalidCeremony }
    let verified: VerifiedAuthentication
    do {
      verified = try configuration.manager.finishAuthentication(
        credential: response,
        expectedChallenge: Array(challenge.challenge),
        credentialPublicKey: Array(credential.publicKey),
        credentialCurrentSignCount: credential.signCount,
        requireUserVerification: configuration.requireUserVerification)
    } catch {
      throw AuthError.invalidCredential
    }
    var updated = credential
    updated.signCount = verified.newSignCount
    updated.isBackedUp = verified.credentialBackedUp
    updated.lastUsedAt = now()
    try await store.updateCredential(updated)
    let token = try await sessions.create(for: credential.accountID)
    audit(
      .init(
        kind: .passkeyAuthenticated,
        accountID: credential.accountID,
        occurredAt: now()))
    return token
  }

  /// Cancels and invalidates a pending ceremony.
  ///
  /// - Parameter ceremonyID: The opaque identifier to invalidate.
  /// - Throws: An error from durable storage.
  public func cancel(ceremonyID: String) async throws {
    _ = try await store.consumeChallenge(ceremonyID, at: now())
  }

  /// Returns passkeys after recent authentication.
  ///
  /// - Parameters:
  ///   - accountID: The account whose credentials to return.
  ///   - sessionToken: A recently authenticated session owned by that account.
  /// - Returns: Credentials sorted by registration time.
  /// - Throws: An authentication or storage error.
  public func credentials(for accountID: String, authenticatedBy sessionToken: String) async throws
    -> [PasskeyCredential]
  {
    try await sessions.requireRecent(sessionToken, for: accountID)
    return try await store.credentials(for: accountID, at: now())
  }

  /// Renames a passkey after recent authentication.
  ///
  /// - Parameters:
  ///   - id: The credential identifier.
  ///   - name: The new nonempty display name.
  ///   - accountID: The account that must own the credential.
  ///   - sessionToken: A recently authenticated session owned by that account.
  /// - Throws: An authentication, validation, or storage error.
  public func renameCredential(
    _ id: String,
    to name: String,
    accountID: String,
    authenticatedBy sessionToken: String
  ) async throws {
    guard !name.isEmpty else { throw AuthError.invalidInput }
    try await sessions.requireRecent(sessionToken, for: accountID)
    guard var credential = try await store.credential(id: id, at: now()),
      credential.accountID == accountID
    else { throw AuthError.invalidCredential }
    credential.name = name
    try await store.updateCredential(credential)
  }

  /// Removes a passkey when another configured recovery method remains.
  ///
  /// - Parameters:
  ///   - id: The credential identifier.
  ///   - accountID: The account that must own the credential.
  ///   - sessionToken: A recently authenticated session owned by that account.
  /// - Throws: ``AuthError/recoveryUnavailable`` when removing the final credential would strand
  ///   the account, or another authentication, validation, or storage error.
  public func removeCredential(
    _ id: String,
    accountID: String,
    authenticatedBy sessionToken: String
  ) async throws {
    try await sessions.requireRecent(sessionToken, for: accountID)
    let credentials = try await store.credentials(for: accountID, at: now())
    guard credentials.contains(where: { $0.id == id }) else { throw AuthError.invalidCredential }
    if credentials.count == 1 {
      let account = try await store.account(id: accountID, at: now())
      guard recoveryPolicy == .magicLink, account?.verifiedEmail != nil else {
        throw AuthError.recoveryUnavailable
      }
    }
    try await store.removeCredential(id: id, accountID: accountID, at: now())
    audit(.init(kind: .passkeyRemoved, accountID: accountID, occurredAt: now()))
  }
}

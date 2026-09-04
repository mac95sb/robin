import Foundation

/// Creates, validates, rotates, and revokes durable authenticated sessions.
public struct AuthSessionManager: Sendable {
  private let store: AuthStore
  private let lifetime: TimeInterval
  private let recentAuthenticationWindow: TimeInterval
  private let now: @Sendable () -> Date
  private let audit: @Sendable (AuthAuditEvent) -> Void

  /// Creates a session manager.
  ///
  /// - Parameters:
  ///   - store: Durable storage shared by the authentication services.
  ///   - lifetime: The lifetime of each newly issued session, in seconds.
  ///   - recentAuthenticationWindow: The maximum age accepted for sensitive account changes.
  ///   - now: The wall-clock source. Inject a deterministic closure in tests.
  ///   - audit: A synchronous receiver for redacted authentication events.
  /// - Precondition: Both time intervals are positive and finite.
  public init(
    store: AuthStore,
    lifetime: TimeInterval = 86_400,
    recentAuthenticationWindow: TimeInterval = 300,
    now: @escaping @Sendable () -> Date = Date.init,
    audit: @escaping @Sendable (AuthAuditEvent) -> Void = { _ in }
  ) {
    precondition(
      lifetime.isFinite && lifetime > 0 && recentAuthenticationWindow.isFinite
        && recentAuthenticationWindow > 0)
    self.store = store
    self.lifetime = lifetime
    self.recentAuthenticationWindow = recentAuthenticationWindow
    self.now = now
    self.audit = audit
  }

  /// Creates a new session after successful authentication.
  ///
  /// - Parameter accountID: The stable identifier of the authenticated account.
  /// - Returns: A bearer token whose plaintext is returned only once.
  /// - Throws: An error from durable session storage.
  public func create(for accountID: String) async throws -> SessionToken {
    let now = now()
    return try await create(
      AuthSession(
        accountID: accountID,
        createdAt: now,
        authenticatedAt: now,
        expiresAt: now.addingTimeInterval(lifetime)))
  }

  /// Returns validated session state.
  ///
  /// - Parameter token: The plaintext bearer token from the request cookie.
  /// - Returns: The unexpired durable session.
  /// - Throws: ``AuthError/invalidSession`` for an unknown, expired, or revoked token, or a storage
  ///   error.
  public func session(for token: String) async throws -> AuthSession {
    guard let session = try await store.session(token: token, at: now()) else {
      throw AuthError.invalidSession
    }
    return session
  }

  /// Rotates a valid bearer token without weakening its authentication time.
  ///
  /// - Parameter token: The current plaintext bearer token.
  /// - Returns: A replacement token. The old token is invalidated atomically before replacement.
  /// - Throws: ``AuthError/invalidSession`` when the token is invalid, or a storage error.
  public func rotate(_ token: String) async throws -> SessionToken {
    let now = now()
    guard let previous = try await store.consumeSession(token: token, at: now) else {
      throw AuthError.invalidSession
    }
    return try await create(
      AuthSession(
        accountID: previous.accountID,
        createdAt: now,
        authenticatedAt: previous.authenticatedAt,
        expiresAt: now.addingTimeInterval(lifetime)))
  }

  /// Revokes a session token for logout or administrative invalidation.
  ///
  /// - Parameter token: The plaintext bearer token to invalidate.
  /// - Throws: An error from durable session storage.
  public func revoke(_ token: String) async throws {
    let accountID = try await store.session(token: token, at: now())?.accountID
    try await store.revokeSession(token: token)
    audit(.init(kind: .sessionRevoked, accountID: accountID, occurredAt: now()))
  }

  /// Requires a valid session whose authentication is recent enough for credential changes.
  ///
  /// - Parameters:
  ///   - token: The plaintext bearer token.
  ///   - accountID: The account that must own the session.
  /// - Throws: ``AuthError/invalidSession`` or ``AuthError/recentAuthenticationRequired`` when the
  ///   session cannot authorize a sensitive change, or a storage error.
  public func requireRecent(_ token: String, for accountID: String) async throws {
    let session = try await session(for: token)
    guard session.accountID == accountID,
      now().timeIntervalSince(session.authenticatedAt) <= recentAuthenticationWindow
    else { throw AuthError.recentAuthenticationRequired }
  }

  private func create(_ session: AuthSession) async throws -> SessionToken {
    let token = randomAuthToken()
    try await store.storeSession(session, token: token)
    audit(.init(kind: .sessionCreated, accountID: session.accountID, occurredAt: now()))
    return SessionToken(value: token, expiresAt: session.expiresAt)
  }
}

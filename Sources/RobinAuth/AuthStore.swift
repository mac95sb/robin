import Foundation
import RobinData

/// Durable authentication state backed by a RobinData key-value store.
public actor AuthStore {
  private let store: any KeyValueStore
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  /// Creates an authentication store over SQLite or another RobinData adapter.
  ///
  /// - Parameter store: Durable namespaced storage shared by every authentication service.
  public init(_ store: any KeyValueStore) { self.store = store }

  /// Persists an account and its unique verified-email index.
  ///
  /// - Parameters:
  ///   - account: The account to insert or update.
  ///   - now: The time used to read an existing email index.
  /// - Throws: ``AuthError/invalidInput`` when another account owns the verified email, or an
  ///   encoding or durable-storage error.
  /// Previously associated email addresses remain reserved to their original account.
  public func save(_ account: Account, at now: Date = Date()) async throws {
    if let email = account.verifiedEmail.flatMap(normalizedEmail) {
      let key = authDigest(email)
      if let owner = try await store.value(
        forKey: key, namespace: "robin.auth.email-index", at: now)
      {
        guard String(decoding: owner, as: UTF8.self) == account.id else {
          throw AuthError.invalidInput
        }
      } else {
        let inserted = try await store.put(
          Data(account.id.utf8),
          forKey: key,
          namespace: "robin.auth.email-index",
          expiresAt: nil,
          condition: .ifAbsent)
        if !inserted {
          let owner = try await store.value(
            forKey: key, namespace: "robin.auth.email-index", at: now)
          guard owner.map({ String(decoding: $0, as: UTF8.self) }) == account.id else {
            throw AuthError.invalidInput
          }
        }
      }
    }
    _ = try await put(account, key: account.id, namespace: "robin.auth.accounts")
  }

  /// Returns an account by stable identifier.
  ///
  /// - Parameters:
  ///   - id: The stable account identifier.
  ///   - now: The time used to evaluate storage expiration.
  /// - Returns: The account, or `nil` when no account has that identifier.
  /// - Throws: A decoding or durable-storage error.
  public func account(id: String, at now: Date = Date()) async throws -> Account? {
    try await value(Account.self, key: id, namespace: "robin.auth.accounts", at: now)
  }

  /// Returns every passkey registered to an account.
  ///
  /// - Parameters:
  ///   - accountID: The stable account identifier.
  ///   - now: The time used to evaluate storage expiration.
  /// - Returns: Credentials sorted by registration time, or an empty array when none exist.
  /// - Throws: A decoding or durable-storage error.
  public func credentials(for accountID: String, at now: Date = Date()) async throws
    -> [PasskeyCredential]
  {
    let ids =
      try await value(
        [String].self, key: accountID, namespace: "robin.auth.credential-index", at: now) ?? []
    var credentials: [PasskeyCredential] = []
    for id in ids {
      if let credential = try await credential(id: id, at: now) { credentials.append(credential) }
    }
    return credentials.sorted { $0.createdAt < $1.createdAt }
  }

  /// Returns the account that owns a normalized, verified email address.
  ///
  /// External identity plugins use this lookup only after their provider has verified the email.
  public func account(verifiedEmail email: String, at now: Date = Date()) async throws -> Account? {
    guard let email = normalizedEmail(email),
      let data = try await store.value(
        forKey: authDigest(email), namespace: "robin.auth.email-index", at: now)
    else { return nil }
    guard let account = try await account(id: String(decoding: data, as: UTF8.self), at: now),
      account.verifiedEmail.flatMap(normalizedEmail) == email
    else { return nil }
    return account
  }

  package func saveCredential(_ credential: PasskeyCredential) async throws -> Bool {
    let inserted = try await put(
      credential,
      key: authDigest(credential.id),
      namespace: "robin.auth.credentials",
      condition: .ifAbsent)
    guard inserted else { return false }
    var ids =
      try await value(
        [String].self,
        key: credential.accountID,
        namespace: "robin.auth.credential-index",
        at: credential.createdAt) ?? []
    ids.append(credential.id)
    _ = try await put(
      Array(Set(ids)).sorted(),
      key: credential.accountID,
      namespace: "robin.auth.credential-index")
    return true
  }

  package func updateCredential(_ credential: PasskeyCredential) async throws {
    _ = try await put(
      credential, key: authDigest(credential.id), namespace: "robin.auth.credentials")
  }

  package func credential(id: String, at now: Date) async throws -> PasskeyCredential? {
    try await value(
      PasskeyCredential.self,
      key: authDigest(id),
      namespace: "robin.auth.credentials",
      at: now)
  }

  package func removeCredential(id: String, accountID: String, at now: Date) async throws {
    _ = try await store.removeValue(
      forKey: authDigest(id), namespace: "robin.auth.credentials")
    let ids = try await credentials(for: accountID, at: now).map(\.id)
    _ = try await put(ids, key: accountID, namespace: "robin.auth.credential-index")
  }

  package func storeChallenge(_ challenge: StoredChallenge) async throws -> String {
    let token = randomAuthToken()
    _ = try await put(
      challenge,
      key: authDigest(token),
      namespace: "robin.auth.challenges",
      expiresAt: challenge.expiresAt,
      condition: .ifAbsent)
    return token
  }

  package func consumeChallenge(_ token: String, at now: Date) async throws -> StoredChallenge? {
    try await consume(
      StoredChallenge.self,
      key: authDigest(token),
      namespace: "robin.auth.challenges",
      at: now)
  }

  package func storeSession(_ session: AuthSession, token: String) async throws {
    _ = try await put(
      session,
      key: authDigest(token),
      namespace: "robin.auth.sessions",
      expiresAt: session.expiresAt,
      condition: .ifAbsent)
  }

  package func session(token: String, at now: Date) async throws -> AuthSession? {
    try await value(
      AuthSession.self,
      key: authDigest(token),
      namespace: "robin.auth.sessions",
      at: now)
  }

  package func consumeSession(token: String, at now: Date) async throws -> AuthSession? {
    try await consume(
      AuthSession.self,
      key: authDigest(token),
      namespace: "robin.auth.sessions",
      at: now)
  }

  package func revokeSession(token: String) async throws {
    _ = try await store.removeValue(forKey: authDigest(token), namespace: "robin.auth.sessions")
  }

  package func storeMagicLink(_ record: StoredMagicLink, token: String) async throws {
    _ = try await put(
      record,
      key: authDigest(token),
      namespace: "robin.auth.magic-links",
      expiresAt: record.expiresAt,
      condition: .ifAbsent)
  }

  package func consumeMagicLink(_ token: String, at now: Date) async throws -> StoredMagicLink? {
    try await consume(
      StoredMagicLink.self,
      key: authDigest(token),
      namespace: "robin.auth.magic-links",
      at: now)
  }

  private func put<Value: Encodable>(
    _ value: Value,
    key: String,
    namespace: String,
    expiresAt: Date? = nil,
    condition: KeyValueWriteCondition = .always
  ) async throws -> Bool {
    try await store.put(
      encoder.encode(value),
      forKey: key,
      namespace: namespace,
      expiresAt: expiresAt,
      condition: condition)
  }

  private func value<Value: Decodable>(
    _ type: Value.Type,
    key: String,
    namespace: String,
    at now: Date
  ) async throws -> Value? {
    guard let data = try await store.value(forKey: key, namespace: namespace, at: now) else {
      return nil
    }
    return try decoder.decode(type, from: data)
  }

  private func consume<Value: Decodable>(
    _ type: Value.Type,
    key: String,
    namespace: String,
    at now: Date
  ) async throws -> Value? {
    guard let data = try await store.consumeValue(forKey: key, namespace: namespace, at: now)
    else { return nil }
    return try decoder.decode(type, from: data)
  }
}

package struct StoredChallenge: Codable, Sendable {
  enum Purpose: String, Codable, Sendable { case registration, authentication }
  let purpose: Purpose
  let account: Account?
  let challenge: Data
  let expiresAt: Date
}

package struct StoredMagicLink: Codable, Sendable {
  let email: String
  let accountName: String?
  let accountID: String?
  let purpose: MagicLinkPurpose
  let redirect: String
  let expiresAt: Date
}

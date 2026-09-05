import Crypto
import Foundation
import RobinEmail

/// Opt-in email magic-link sign-in, bootstrap, and recovery.
public struct MagicLinkService: Sendable {
  private let configuration: MagicLinkConfiguration
  private let sender: any EmailSender
  private let store: AuthStore
  private let sessions: AuthSessionManager
  private let now: @Sendable () -> Date
  private let limiter: AuthRateLimiter
  private let requestLimit: Int
  private let recoveryPolicy: RecoveryPolicy
  private let audit: @Sendable (AuthAuditEvent) -> Void

  /// Creates an enabled magic-link service.
  ///
  /// - Parameters:
  ///   - configuration: Validated link and email settings.
  ///   - sender: The RobinEmail transport used for delivery.
  ///   - store: Durable account and token storage.
  ///   - sessions: The session issuer used after successful consumption.
  ///   - now: The wall-clock source. Inject a deterministic closure in tests.
  ///   - requestLimit: The maximum requests per email and client identity in one minute.
  ///   - recoveryPolicy: Whether verified email can recover existing accounts.
  ///   - audit: A synchronous receiver for redacted authentication events.
  /// - Precondition: `requestLimit` is positive.
  public init(
    configuration: MagicLinkConfiguration,
    sender: any EmailSender,
    store: AuthStore,
    sessions: AuthSessionManager,
    now: @escaping @Sendable () -> Date = Date.init,
    requestLimit: Int = 5,
    recoveryPolicy: RecoveryPolicy = .magicLink,
    audit: @escaping @Sendable (AuthAuditEvent) -> Void = { _ in }
  ) {
    self.configuration = configuration
    self.sender = sender
    self.store = store
    self.sessions = sessions
    precondition(requestLimit > 0)
    self.now = now
    self.limiter = AuthRateLimiter(now: now)
    self.requestLimit = requestLimit
    self.recoveryPolicy = recoveryPolicy
    self.audit = audit
  }

  /// Requests a single-use link without revealing whether an account exists.
  ///
  /// Invalid email and unknown accounts complete without sending a message. This keeps the
  /// observable result identical to a valid request.
  ///
  /// - Parameters:
  ///   - rawEmail: The email address to normalize and verify.
  ///   - accountName: The display name for a newly bootstrapped account.
  ///   - purpose: The account operation authorized by the link.
  ///   - redirect: A same-origin path used after successful consumption.
  ///   - clientIdentity: A nonempty, trusted rate-limit identity such as the resolved client IP.
  /// - Throws: ``AuthError`` for unsafe input or rate limiting, or an error from storage or email
  ///   delivery.
  public func requestLink(
    for rawEmail: String,
    accountName: String? = nil,
    purpose: MagicLinkPurpose = .signIn,
    redirect: String = "/",
    clientIdentity: String
  ) async throws {
    guard safeRedirect(redirect) else { throw AuthError.invalidRedirect }
    guard !clientIdentity.isEmpty else { throw AuthError.invalidInput }
    guard let email = normalizedEmail(rawEmail) else { return }
    do {
      try await limiter.check(
        route: "magic-link.\(purpose.rawValue)",
        identity: "\(clientIdentity):\(authDigest(email))",
        limit: requestLimit)
    } catch {
      audit(.init(kind: .rateLimited, accountID: nil, occurredAt: now()))
      throw error
    }
    let account = try await store.account(verifiedEmail: email, at: now())
    if purpose == .recovery, recoveryPolicy != .magicLink {
      return
    }
    guard purpose == .bootstrap || account != nil else {
      audit(.init(kind: .magicLinkRequested, accountID: nil, occurredAt: now()))
      return
    }
    let nonce = randomAuthToken()
    let token = "\(nonce).\(signature(for: nonce))"
    let record = StoredMagicLink(
      email: email,
      accountName: accountName,
      accountID: account?.id,
      purpose: purpose,
      redirect: redirect,
      expiresAt: now().addingTimeInterval(configuration.lifetime))
    try await store.storeMagicLink(record, token: token)
    var destination = configuration.callbackURL
    destination.append(queryItems: [URLQueryItem(name: "token", value: token)])
    let recipient = try EmailAddress(email)
    let message = try MagicLinkEmail.message(
      applicationName: configuration.applicationName,
      destination: destination,
      validForMinutes: max(1, Int(configuration.lifetime / 60)),
      from: configuration.sender,
      to: recipient)
    _ = try await sender.send(
      message,
      envelope: EmailEnvelope(sender: configuration.sender, recipients: [recipient]))
    audit(.init(kind: .magicLinkRequested, accountID: account?.id, occurredAt: now()))
  }

  /// Atomically consumes a valid signed link and creates a session.
  ///
  /// - Parameter token: The signed, single-use token from the callback URL.
  /// - Returns: The verified account, new session token, and validated redirect path.
  /// - Throws: ``AuthError/invalidCredential`` for an invalid, expired, or replayed token, or an
  ///   error from durable storage.
  public func consume(token: String) async throws -> MagicLinkConsumption {
    let parts = token.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 2, valid(signature: String(parts[1]), for: String(parts[0])),
      let record = try await store.consumeMagicLink(token, at: now())
    else { throw AuthError.invalidCredential }
    let account: Account
    if let accountID = record.accountID {
      guard let existing = try await store.account(id: accountID, at: now()),
        existing.verifiedEmail.flatMap(normalizedEmail) == record.email
      else { throw AuthError.invalidCredential }
      account = existing
    } else if record.purpose == .bootstrap,
      let existing = try await store.account(verifiedEmail: record.email, at: now())
    {
      account = existing
    } else {
      guard record.purpose == .bootstrap else { throw AuthError.invalidCredential }
      let accountName = record.accountName.flatMap { $0.isEmpty ? nil : $0 } ?? record.email
      account = try Account(
        name: accountName,
        verifiedEmail: record.email,
        createdAt: now())
      try await store.save(account, at: now())
    }
    let session = try await sessions.create(for: account.id)
    audit(.init(kind: .magicLinkConsumed, accountID: account.id, occurredAt: now()))
    return MagicLinkConsumption(account: account, session: session, redirect: record.redirect)
  }

  private func signature(for nonce: String) -> String {
    configuration.signingKey.withValue { bytes in
      Data(HMAC<SHA256>.authenticationCode(for: Data(nonce.utf8), using: SymmetricKey(data: bytes)))
        .base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    }
  }

  private func valid(signature supplied: String, for nonce: String) -> Bool {
    guard let supplied = Data(base64URL: supplied) else { return false }
    return configuration.signingKey.withValue { bytes in
      HMAC<SHA256>.isValidAuthenticationCode(
        supplied,
        authenticating: Data(nonce.utf8),
        using: SymmetricKey(data: bytes))
    }
  }
}

extension Data {
  fileprivate init?(base64URL: String) {
    var value = base64URL.replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    while value.count.isMultiple(of: 4) == false { value += "=" }
    self.init(base64Encoded: value)
  }
}

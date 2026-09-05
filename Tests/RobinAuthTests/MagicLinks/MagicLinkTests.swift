import Foundation
import RobinCore
import RobinData
import RobinEmail
import Testing

@testable import RobinAuth

@Suite("Email magic links")
struct MagicLinkTests {
  @Test func changedEmailRejectsOldLookupAndPendingLinks() async throws {
    let database = try await TestDatabase.sqlite()
    let values = try await DatabaseKeyValueStore(database: database.database)
    let store = AuthStore(values)
    let mailbox = DevelopmentMailbox()
    let service = MagicLinkService(
      configuration: try configuration(), sender: mailbox,
      store: store, sessions: AuthSessionManager(store: store))
    for purpose in [MagicLinkPurpose.signIn, .recovery, .bootstrap] {
      for replacement in [String?.none, "new@example.com"] {
        let id = UUID().uuidString
        let oldEmail = "\(id)@example.com"
        let account = try Account(id: id, name: "Member", verifiedEmail: oldEmail)
        try await store.save(account)
        try await service.requestLink(for: oldEmail, purpose: purpose, clientIdentity: id)
        let pending = try token(from: #require(await mailbox.allMessages().last?.message.text))
        let newEmail = replacement.map { "\(id)-\($0)" }
        try await store.save(Account(id: id, name: "Member", verifiedEmail: newEmail))
        #expect(try await store.account(verifiedEmail: oldEmail) == nil)
        if let newEmail { #expect(try await store.account(verifiedEmail: newEmail)?.id == id) }
        await #expect(throws: AuthError.invalidCredential) {
          try await service.consume(token: pending)
        }
        let count = await mailbox.allMessages().count
        try await service.requestLink(for: oldEmail, purpose: .signIn, clientIdentity: id)
        #expect(await mailbox.allMessages().count == count)
      }
    }
    try await database.remove()
  }
  @Test func bootstrapIsVerifiedSingleUseAndEnumerationResistant() async throws {
    let date = MutableDate(Date(timeIntervalSince1970: 2_000))
    let testDatabase = try await TestDatabase.sqlite()
    let keyValues = try await DatabaseKeyValueStore(database: testDatabase.database, now: date.get)
    let store = AuthStore(keyValues)
    let sessions = AuthSessionManager(store: store, now: date.get)
    let mailbox = DevelopmentMailbox(now: date.get)
    let service = MagicLinkService(
      configuration: try configuration(),
      sender: mailbox,
      store: store,
      sessions: sessions,
      now: date.get)

    try await service.requestLink(
      for: "person@example.com",
      accountName: "Person",
      purpose: .bootstrap,
      redirect: "/settings",
      clientIdentity: "client")
    try await service.requestLink(
      for: "person@example.com", accountName: "Person", purpose: .bootstrap,
      clientIdentity: "client")
    let messages = await mailbox.allMessages()
    let message = try #require(messages.first?.message)
    #expect(message.html.contains("Sign in"))
    #expect(message.text.contains("https://example.com/auth/magic?token="))
    let firstToken = try token(from: message.text)
    let concurrentToken = try token(from: #require(messages.last?.message.text))
    let result = try await service.consume(token: firstToken)
    #expect(result.account.name == "Person")
    #expect(result.account.verifiedEmail == "person@example.com")
    #expect(result.redirect == "/settings")
    #expect(try await sessions.session(for: result.session.value).accountID == result.account.id)
    #expect(try await service.consume(token: concurrentToken).account.id == result.account.id)
    let duplicate = try Account(name: "Duplicate", verifiedEmail: "person@example.com")
    await #expect(throws: AuthError.invalidInput) {
      try await store.save(duplicate, at: date.get())
    }
    await #expect(throws: AuthError.invalidCredential) {
      try await service.consume(token: firstToken)
    }

    try await service.requestLink(
      for: "missing@example.com", purpose: .signIn, clientIdentity: "client")
    #expect(await mailbox.allMessages().count == 2)
    await #expect(throws: AuthError.invalidRedirect) {
      try await service.requestLink(
        for: "person@example.com", redirect: "https://evil.example", clientIdentity: "client")
    }
    try await testDatabase.remove()
  }

  @Test func linksExpireAndRequestsAreIdentityRateLimited() async throws {
    let date = MutableDate(Date(timeIntervalSince1970: 3_000))
    let testDatabase = try await TestDatabase.sqlite()
    let keyValues = try await DatabaseKeyValueStore(database: testDatabase.database, now: date.get)
    let store = AuthStore(keyValues)
    let sessions = AuthSessionManager(store: store, now: date.get)
    let mailbox = DevelopmentMailbox(now: date.get)
    let service = MagicLinkService(
      configuration: try configuration(lifetime: 10),
      sender: mailbox,
      store: store,
      sessions: sessions,
      now: date.get,
      requestLimit: 1)

    try await service.requestLink(
      for: "person@example.com", purpose: .bootstrap, clientIdentity: "client")
    let token = try token(from: #require(await mailbox.allMessages().first?.message.text))
    await #expect(throws: AuthError.rateLimited) {
      try await service.requestLink(
        for: "person@example.com", purpose: .bootstrap, clientIdentity: "client")
    }
    date.value = date.value.addingTimeInterval(11)
    await #expect(throws: AuthError.invalidCredential) { try await service.consume(token: token) }
    try await testDatabase.remove()
  }

  private func configuration(lifetime: TimeInterval = 900) throws -> MagicLinkConfiguration {
    try MagicLinkConfiguration(
      applicationName: "Example",
      callbackURL: #require(URL(string: "https://example.com/auth/magic")),
      sender: EmailAddress("auth@example.com"),
      signingKey: Secret(Data(repeating: 7, count: 32)),
      lifetime: lifetime)
  }

  private func token(from text: String) throws -> String {
    let marker = "token="
    let start = try #require(text.range(of: marker)?.upperBound)
    return String(text[start...].prefix { !$0.isWhitespace && $0 != ">" })
  }
}

import Foundation
import HTTPTypes
import RobinData
import RobinServer
import Testing

@testable import RobinAuth

@Suite("Durable auth sessions")
struct AuthSessionTests {
  @Test func sessionAndCSRFCookiesAreBothPreserved() {
    let now = Date(timeIntervalSince1970: 1_000)
    var response = Response.text("OK")

    response.setAuthSessionCookie(
      SessionToken(value: "session", expiresAt: now.addingTimeInterval(60)), now: now)
    response.setAuthCSRFCookie(CSRFToken())

    let cookies = response.head.headerFields[fields: .setCookie].map(\.value)
    #expect(cookies.count == 2)
    #expect(cookies[0].contains("HttpOnly"))
    #expect(!cookies[1].contains("HttpOnly"))
  }

  @Test func sessionsExpireRotateRevokeAndRequireRecentAuthentication() async throws {
    let date = MutableDate(Date(timeIntervalSince1970: 1_000))
    let testDatabase = try await TestDatabase.sqlite()
    let keyValues = try await DatabaseKeyValueStore(database: testDatabase.database, now: date.get)
    let store = AuthStore(keyValues)
    let sessions = AuthSessionManager(
      store: store,
      lifetime: 60,
      recentAuthenticationWindow: 10,
      now: date.get)

    let first = try await sessions.create(for: "account")
    #expect(try await sessions.session(for: first.value).accountID == "account")
    let second = try await sessions.rotate(first.value)
    await #expect(throws: AuthError.invalidSession) { try await sessions.session(for: first.value) }
    try await sessions.requireRecent(second.value, for: "account")

    date.value = date.value.addingTimeInterval(11)
    await #expect(throws: AuthError.recentAuthenticationRequired) {
      try await sessions.requireRecent(second.value, for: "account")
    }
    try await sessions.revoke(second.value)
    await #expect(throws: AuthError.invalidSession) {
      try await sessions.session(for: second.value)
    }
    try await testDatabase.remove()
  }
}

final class MutableDate: @unchecked Sendable {
  var value: Date
  init(_ value: Date) { self.value = value }
  func get() -> Date { value }
}

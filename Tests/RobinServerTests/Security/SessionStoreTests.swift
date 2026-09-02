import Testing

@testable import RobinServer

@Suite("Session store")
struct SessionStoreTests {
  @Test func sessionsRotateAndRevokeTokens() async {
    let sessions = SessionStore<String>()
    let first = await sessions.create("user-1")
    let second = await sessions.rotate(first)

    #expect(await sessions.value(for: first) == nil)
    #expect(await sessions.value(for: second!) == "user-1")
    await sessions.revoke(second!)
    #expect(await sessions.value(for: second!) == nil)
  }
}

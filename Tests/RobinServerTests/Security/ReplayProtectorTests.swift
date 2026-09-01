import Testing

@testable import RobinServer

@Suite("Replay protector")
struct ReplayProtectorTests {
  @Test func replayProtectionIsBounded() async {
    let protector = ReplayProtector(capacity: 2)
    #expect(await protector.accept("one"))
    #expect(await protector.accept("one") == false)
    #expect(await protector.accept("two"))
    #expect(await protector.accept("three"))
    #expect(await protector.accept("one"))
  }
}

import Testing

@testable import RobinServer

@Suite("Server-sent events")
struct ServerSentEventTests {
  @Test func payloadLineEndingsCannotInjectEvents() {
    let event = ServerSentEvent(data: "one\r\nevent: forged\r\rid: attacker\nretry: 1\n")
    #expect(
      String(decoding: event.encoded, as: UTF8.self)
        == "data: one\ndata: event: forged\ndata: \ndata: id: attacker\ndata: retry: 1\ndata: \n\n")
  }
  @Test func retryPreservesSubsecondMilliseconds() {
    let event = ServerSentEvent(data: "ready", retry: .milliseconds(500))

    #expect(String(decoding: event.encoded, as: UTF8.self).contains("retry: 500\n"))
  }
}

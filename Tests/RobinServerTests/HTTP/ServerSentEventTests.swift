import Testing

@testable import RobinServer

@Suite("Server-sent events")
struct ServerSentEventTests {
  @Test func retryPreservesSubsecondMilliseconds() {
    let event = ServerSentEvent(data: "ready", retry: .milliseconds(500))

    #expect(String(decoding: event.encoded, as: UTF8.self).contains("retry: 500\n"))
  }
}

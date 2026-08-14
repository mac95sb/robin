import NIOCore
import Testing

@testable import RobinCore

@Suite("Noncopyable request bodies")
struct RequestBodyTests {
  @Test func consumingBodyPreservesReadableBytes() {
    let body = RequestBody(ByteBuffer(string: "Robin"))
    let consumed = body.consume()
    #expect(consumed.readableBytes == 5)
  }
}

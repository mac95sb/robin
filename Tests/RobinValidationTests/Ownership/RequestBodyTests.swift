import NIOCore
import Testing

@testable import RobinValidation

@Suite("Noncopyable request bodies and span-scoped checksums")
struct RequestBodyTests {
  @Test func consumingBodyPreservesReadableBytesAndChecksum() {
    let body = RequestBody(ByteBuffer(string: "Robin"))
    let consumed = body.consume()
    #expect(consumed.readableBytes == 5)
    #expect(ByteBufferSpan.checksum(consumed) == 79_133_066)
  }
}

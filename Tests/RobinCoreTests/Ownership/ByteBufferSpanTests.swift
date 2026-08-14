import NIOCore
import Testing

@testable import RobinCore

@Suite("Span-scoped byte-buffer checksums")
struct ByteBufferSpanTests {
  @Test func checksumUsesReadableBytes() {
    let buffer = ByteBuffer(string: "Robin")
    #expect(ByteBufferSpan.checksum(buffer) == 79_133_066)
  }
}

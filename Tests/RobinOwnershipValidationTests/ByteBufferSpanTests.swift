import NIOCore
import Testing

@testable import RobinOwnershipValidation

@Test func checksumUsesReadableBytes() {
  let buffer = ByteBuffer(string: "Robin")
  #expect(ByteBufferSpan.checksum(buffer) == 79_133_066)
}

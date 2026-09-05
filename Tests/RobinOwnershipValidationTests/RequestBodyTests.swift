import NIOCore
import Testing

@testable import RobinOwnershipValidation

@Test func consumingBodyPreservesReadableBytes() {
  let body = RequestBody(ByteBuffer(string: "Robin"))
  #expect(body.checksum() == 79_133_066)
  let consumed = body.consume()
  #expect(consumed.readableBytes == 5)
}

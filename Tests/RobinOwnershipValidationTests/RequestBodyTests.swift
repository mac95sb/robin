import NIOCore
import Testing

@testable import RobinOwnershipValidation

@Test func consumingBodyPreservesReadableBytes() {
  let body = RequestBody(ByteBuffer(string: "Robin"))
  let consumed = body.consume()
  #expect(consumed.readableBytes == 5)
}

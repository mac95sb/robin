import NIOCore

/// Operations that borrow a byte buffer's readable storage without copying it.
public enum ByteBufferSpan {
  /// Borrows NIO's readable storage only for the duration of the closure.
  ///
  /// The three `unsafe` acknowledgements are intentionally local: NIO keeps the storage alive and
  /// immutable while `withUnsafeReadableBytes` runs, `bindMemory` views initialized readable bytes
  /// as `UInt8`, and the resulting nonescapable `Span` cannot outlive that closure.
  ///
  /// - Parameter buffer: The buffer whose readable bytes are checksummed. Borrowed, not consumed.
  /// - Returns: A 64-bit FNV-style checksum of the readable bytes.
  public static func checksum(_ buffer: borrowing ByteBuffer) -> UInt64 {
    unsafe buffer.withUnsafeReadableBytes { rawBytes in
      let bytes = unsafe rawBytes.bindMemory(to: UInt8.self)
      return unsafe checksum(bytes.span)
    }
  }

  private static func checksum(_ bytes: borrowing Span<UInt8>) -> UInt64 {
    var result: UInt64 = 0
    for index in bytes.indices { result = result &* 31 &+ UInt64(bytes[index]) }
    return result
  }
}

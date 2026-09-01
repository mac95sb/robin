import NIOCore

/// Validation-only operations that borrow a byte buffer's readable storage without copying it.
public enum ByteBufferSpan {
  /// Computes a deterministic checksum while borrowing readable bytes in place.
  ///
  /// - Parameter buffer: The byte buffer whose readable region is inspected.
  /// - Returns: The validation checksum.
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

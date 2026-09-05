import NIOCore

/// A validation-only request body whose byte buffer can be consumed exactly once.
public struct RequestBody: ~Copyable {
  private var buffer: ByteBuffer

  /// Creates a single-consumption request body.
  ///
  /// - Parameter buffer: The byte buffer transferred into the body.
  public init(_ buffer: consuming ByteBuffer) { self.buffer = buffer }

  /// Borrows the temporary body storage without consuming or copying its readable bytes.
  public borrowing func checksum() -> UInt64 { ByteBufferSpan.checksum(buffer) }
  /// Transfers the stored byte buffer to the caller.
  ///
  /// - Returns: The consumed byte buffer.
  public consuming func consume() -> ByteBuffer { buffer }
}

import NIOCore

/// A request body whose byte buffer can be consumed exactly once.
///
/// `RequestBody` is noncopyable (`~Copyable`), so passing it on transfers
/// ownership and the compiler rejects double consumption at build time.
public struct RequestBody: ~Copyable {
  private var buffer: ByteBuffer

  /// Creates a request body taking ownership of `buffer`.
  ///
  /// - Parameter buffer: The body bytes. The buffer is moved, not copied.
  public init(_ buffer: consuming ByteBuffer) {
    self.buffer = buffer
  }

  /// Transfers ownership of the underlying byte buffer.
  ///
  /// Consuming the body invalidates the value; it cannot be consumed again.
  ///
  /// - Returns: The body bytes.
  public consuming func consume() -> ByteBuffer { buffer }
}

import NIOCore

/// A validation-only request body whose byte buffer can be consumed exactly once.
public struct RequestBody: ~Copyable {
  private var buffer: ByteBuffer

  public init(_ buffer: consuming ByteBuffer) { self.buffer = buffer }
  public consuming func consume() -> ByteBuffer { buffer }
}

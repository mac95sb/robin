import NIOCore
import RobinRendering

/// Converts rendered HTML into deterministic byte-buffer chunks.
public enum StreamedHTML {
  /// Renders a node and divides its UTF-8 bytes into chunks no larger than `chunkSize`.
  ///
  /// - Precondition: `chunkSize` is greater than zero.
  public static func chunks(for node: RenderNode, chunkSize: Int = 64) -> [ByteBuffer] {
    precondition(chunkSize > 0)
    let bytes = Array(HTMLRenderer.render(node).utf8)
    return stride(from: 0, to: bytes.count, by: chunkSize).map { offset in
      ByteBuffer(bytes: bytes[offset..<min(offset + chunkSize, bytes.count)])
    }
  }
}

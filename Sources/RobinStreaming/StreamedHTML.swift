import Algorithms
import NIOCore
import RobinHTML

/// Converts rendered HTML into deterministic byte-buffer chunks.
public enum StreamedHTML {
  /// Renders a node and divides its UTF-8 bytes into chunks no larger than `chunkSize`.
  ///
  /// - Precondition: `chunkSize` is greater than zero.
  public static func chunks(for node: RenderNode, chunkSize: Int = 64) throws -> [ByteBuffer] {
    precondition(chunkSize > 0)
    let bytes = Array(try HTMLRenderer.render(node).utf8)
    return bytes.chunks(ofCount: chunkSize).map(ByteBuffer.init(bytes:))
  }
}

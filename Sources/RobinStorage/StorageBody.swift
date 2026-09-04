import Foundation
import NIOCore

/// A repeatable asynchronous byte stream.
public struct StorageBody: AsyncSequence, Sendable {
  /// One streamed byte chunk.
  public typealias Element = ByteBuffer
  /// Errors produced while reading a body.
  public typealias Failure = Error
  /// An iterator over streamed byte chunks.
  public typealias AsyncIterator = AsyncThrowingStream<ByteBuffer, Error>.Iterator

  private let stream: @Sendable () -> AsyncThrowingStream<ByteBuffer, Error>

  /// Creates a body from a repeatable stream factory.
  public init(
    _ stream: @escaping @Sendable () -> AsyncThrowingStream<ByteBuffer, Error>
  ) {
    self.stream = stream
  }

  /// Creates a body containing in-memory bytes.
  public static func bytes(_ data: Data) -> Self {
    Self {
      AsyncThrowingStream { continuation in
        continuation.yield(ByteBuffer(bytes: data))
        continuation.finish()
      }
    }
  }

  /// Creates a fresh iterator over the body's chunks.
  public func makeAsyncIterator() -> AsyncIterator { stream().makeAsyncIterator() }

  package func chunks() -> AsyncThrowingStream<ByteBuffer, Error> { stream() }
}

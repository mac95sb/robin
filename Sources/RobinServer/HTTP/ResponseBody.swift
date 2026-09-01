import Foundation

/// Content produced by a transport-neutral response.
public enum ResponseBody: Sendable {
  /// A complete in-memory body.
  case bytes([UInt8])
  /// Byte chunks produced with transport backpressure.
  case stream(AsyncThrowingStream<[UInt8], any Error>)
  /// Server-sent events produced over a long-lived response.
  case serverSentEvents(AsyncStream<ServerSentEvent>)
  /// A file streamed from an explicitly persistent filesystem.
  case file(URL)
  /// A WebSocket session accepted during an HTTP/1 upgrade.
  case webSocket(WebSocketSession)

  /// Returns the complete bytes when this is a buffered body.
  public var bufferedBytes: [UInt8]? {
    guard case .bytes(let bytes) = self else { return nil }
    return bytes
  }
}

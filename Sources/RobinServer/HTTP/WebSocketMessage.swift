/// An application-level WebSocket message.
public enum WebSocketMessage: Equatable, Sendable {
  /// A complete UTF-8 text message.
  case text(String)
  /// A complete binary message.
  case binary([UInt8])
}

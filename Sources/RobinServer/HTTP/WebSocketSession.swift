/// Runs one WebSocket connection until its input ends or the task is cancelled.
public struct WebSocketSession: Sendable {
  package let operation:
    @Sendable (WebSocketConnection, AsyncStream<WebSocketMessage>) async throws -> Void

  /// Creates a session operation that receives the connection and its incoming messages.
  public init(
    _ operation:
      @escaping @Sendable (
        WebSocketConnection,
        AsyncStream<WebSocketMessage>
      ) async throws -> Void
  ) {
    self.operation = operation
  }
}

extension Response {
  /// Accepts a WebSocket session when the transport supports HTTP upgrades.
  public static func webSocket(_ session: WebSocketSession) -> Self {
    Self(body: .webSocket(session))
  }
}

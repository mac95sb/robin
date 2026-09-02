/// An application-level WebSocket message.
public enum WebSocketMessage: Equatable, Sendable {
  /// A complete UTF-8 text message.
  case text(String)
  /// A complete binary message.
  case binary([UInt8])
}

/// Operations available while a WebSocket is connected.
public struct WebSocketConnection: Sendable {
  private let sendOperation: @Sendable (WebSocketMessage) async throws -> Void
  private let closeOperation: @Sendable () async throws -> Void

  package init(
    send: @escaping @Sendable (WebSocketMessage) async throws -> Void,
    close: @escaping @Sendable () async throws -> Void
  ) {
    self.sendOperation = send
    self.closeOperation = close
  }

  /// Sends one complete message with transport backpressure.
  public func send(_ message: WebSocketMessage) async throws {
    try await sendOperation(message)
  }

  /// Sends a normal close frame.
  public func close() async throws {
    try await closeOperation()
  }
}

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

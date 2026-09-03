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
  ///
  /// - Parameter message: The text or binary message to send.
  /// - Throws: A transport error when the message cannot be sent.
  public func send(_ message: WebSocketMessage) async throws {
    try await sendOperation(message)
  }

  /// Sends a normal close frame.
  ///
  /// - Throws: A transport error when the connection cannot be closed.
  public func close() async throws {
    try await closeOperation()
  }
}

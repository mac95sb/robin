import HTTPTypes

extension Response {
  /// Creates a response whose byte chunks are written with transport backpressure.
  public static func stream(
    _ body: AsyncThrowingStream<[UInt8], any Error>,
    status: HTTPResponse.Status = .ok,
    headers: HTTPFields = [:]
  ) -> Self {
    Self(status: status, headers: headers, body: .stream(body))
  }

  /// Creates a server-sent event response.
  public static func serverSentEvents(_ events: AsyncStream<ServerSentEvent>) -> Self {
    Self(
      headers: [
        .contentType: "text/event-stream; charset=utf-8",
        .cacheControl: "no-cache",
      ],
      body: .serverSentEvents(events)
    )
  }
}

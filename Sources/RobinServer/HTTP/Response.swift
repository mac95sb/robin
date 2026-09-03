import Foundation
import HTTPTypes

/// A transport-neutral HTTP response produced by Robin application code.
public struct Response: Sendable {
  /// The response status and header fields.
  public var head: HTTPResponse
  /// The response body and its transport requirements.
  public var body: ResponseBody

  /// Creates a response from normalized HTTP values.
  ///
  /// - Parameters:
  ///   - status: The response status.
  ///   - headers: Response header fields.
  ///   - body: The complete response body.
  public init(
    status: HTTPResponse.Status = .ok,
    headers: HTTPFields = [:],
    body: [UInt8] = []
  ) {
    self.head = HTTPResponse(status: status, headerFields: headers)
    self.body = .bytes(body)
  }

  /// Creates a response with a streaming, file, event, or WebSocket body.
  public init(
    status: HTTPResponse.Status = .ok,
    headers: HTTPFields = [:],
    body: ResponseBody
  ) {
    self.head = HTTPResponse(status: status, headerFields: headers)
    self.body = body
  }

  /// Creates a UTF-8 plain-text response.
  public static func text(_ value: String, status: HTTPResponse.Status = .ok) -> Self {
    Self(
      status: status,
      headers: [.contentType: "text/plain; charset=utf-8"],
      body: Array(value.utf8)
    )
  }

  /// Creates a UTF-8 HTML response.
  public static func html(_ value: String, status: HTTPResponse.Status = .ok) -> Self {
    Self(
      status: status,
      headers: [.contentType: "text/html; charset=utf-8"],
      body: Array(value.utf8)
    )
  }

  /// Creates a JSON response.
  ///
  /// - Parameters:
  ///   - value: The value to encode.
  ///   - status: The response status.
  ///   - encoder: The configured JSON encoder.
  /// - Throws: An encoding error produced by `encoder`.
  public static func json<Value: Encodable & Sendable>(
    _ value: Value,
    status: HTTPResponse.Status = .ok,
    encoder: JSONEncoder = JSONEncoder()
  ) throws -> Self {
    let data = try encoder.encode(value)
    return Self(
      status: status,
      headers: [.contentType: "application/json"],
      body: Array(data)
    )
  }
}

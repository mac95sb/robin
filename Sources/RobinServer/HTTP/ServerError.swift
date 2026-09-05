import HTTPTypes

/// Errors Robin can safely map to an HTTP response.
public struct ServerError: Error, Sendable {
  /// The status returned to the client.
  public let status: HTTPResponse.Status
  /// The message safe to include in a client response.
  public let publicMessage: String
  /// Response header fields carried by the error.
  public let headers: HTTPFields
  /// The response representation preferred by the error.
  public let preferredRepresentation: ServerErrorRepresentation
  /// Internal diagnostic details that are never sent to the client.
  public let internalDescription: String?

  /// Creates a client-safe server error.
  public init(
    _ status: HTTPResponse.Status,
    _ publicMessage: String,
    headers: HTTPFields = [:],
    preferredRepresentation: ServerErrorRepresentation = .automatic,
    internalDescription: String? = nil
  ) {
    self.status = status
    self.publicMessage = publicMessage
    self.headers = headers
    self.preferredRepresentation = preferredRepresentation
    self.internalDescription = internalDescription
  }
}

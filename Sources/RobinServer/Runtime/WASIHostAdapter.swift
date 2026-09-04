/// Maps a WASI host's generated HTTP bindings to Robin HTTP values.
public protocol WASIHostAdapter: Sendable {
  /// The incoming request type generated for the host.
  associatedtype IncomingRequest: Sendable
  /// The outgoing response type generated for the host.
  associatedtype OutgoingResponse: Sendable

  /// Converts a host request into Robin's normalized request.
  ///
  /// - Parameter incoming: The request value produced by the host bindings.
  /// - Returns: A normalized Robin request.
  /// - Throws: An adapter-specific error when the request cannot be represented.
  func request(from incoming: IncomingRequest) throws -> Request

  /// Converts a buffered Robin response into the host response type.
  ///
  /// - Parameter outgoing: The response produced by the application.
  /// - Returns: A response value accepted by the host bindings.
  /// - Throws: An adapter-specific error when the response cannot be represented.
  func response(from outgoing: Response) throws -> OutgoingResponse
}

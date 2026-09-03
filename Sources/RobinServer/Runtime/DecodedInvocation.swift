/// A normalized request and transport context decoded from one provider event.
public struct DecodedInvocation: Sendable {
  /// The request passed to the application responder.
  public let request: Request
  /// The request identifier carried by the event, when present.
  public let requestID: String?
  /// The transport-verified client address, when present.
  public let clientAddress: String?

  /// Creates a decoded invocation.
  ///
  /// - Parameters:
  ///   - request: The request passed to the application responder.
  ///   - requestID: The request identifier carried by the event.
  ///   - clientAddress: The transport-verified client address.
  public init(request: Request, requestID: String? = nil, clientAddress: String? = nil) {
    self.request = request
    self.requestID = requestID
    self.clientAddress = clientAddress
  }
}

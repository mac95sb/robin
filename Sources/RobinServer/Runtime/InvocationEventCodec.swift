/// Converts provider invocation envelopes to and from Robin HTTP values.
public protocol InvocationEventCodec: Sendable {
  /// Decodes one provider event.
  ///
  /// - Parameter payload: The complete provider event bytes.
  /// - Returns: A normalized request and its transport context.
  /// - Throws: A codec-specific error when the event is invalid.
  func decode(_ payload: [UInt8]) throws -> DecodedInvocation

  /// Encodes one normalized response for the provider.
  ///
  /// - Parameter response: The buffered application response.
  /// - Returns: The complete provider response-envelope bytes.
  /// - Throws: A codec-specific error when the response cannot be represented.
  func encode(_ response: Response) throws -> [UInt8]
}

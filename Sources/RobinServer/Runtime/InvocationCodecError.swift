/// An invocation envelope cannot be converted without losing HTTP semantics.
public enum InvocationCodecError: Error, Equatable, Sendable {
  /// The event is not valid for the selected codec.
  case invalidEvent
  /// The event contains an invalid HTTP method.
  case invalidMethod(String)
  /// The event contains an invalid HTTP header name.
  case invalidHeader(String)
  /// The encoded request body is invalid.
  case invalidBody
  /// The response body requires a capability absent from invocation transports.
  case unsupportedResponseBody
}

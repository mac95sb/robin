/// Email validation or transport errors.
public enum EmailError: Error, Equatable, Sendable {
  /// A mailbox value could permit invalid delivery or header injection.
  case invalidAddress
  /// A required header was empty or contained a line break.
  case invalidHeader
  /// A provider returned an unexpected response.
  case unexpectedResponse(Int, String)
  /// A requested SMTP feature was not advertised by the server.
  case unsupportedFeature(String)
  /// SMTP authentication was rejected.
  case authenticationFailed
}

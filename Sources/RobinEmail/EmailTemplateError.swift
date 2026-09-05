/// Email-template validation errors.
public enum EmailTemplateError: Error, Equatable, Sendable {
  /// Email links must use HTTP or HTTPS.
  case unsafeLink
}

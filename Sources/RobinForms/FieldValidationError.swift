/// An error produced while decoding or validating submitted form fields.
public enum FieldValidationError: Error, Equatable, Sendable {
  /// The submitted cross-site request forgery token is invalid.
  case invalidCSRF
  /// A required field is absent.
  case missing(String)
  /// A named field failed validation for the supplied reason.
  case invalid(String, reason: String)
}

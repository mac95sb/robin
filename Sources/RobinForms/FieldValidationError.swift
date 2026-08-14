/// An error produced while decoding or validating submitted form fields.
public enum FieldValidationError: Error, Equatable, Sendable {
  case invalidCSRF
  case missing(String)
  case invalid(String, reason: String)
}

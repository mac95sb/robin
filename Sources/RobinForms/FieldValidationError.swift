/// An error produced while decoding or validating submitted form fields.
public enum FieldValidationError: Error, Equatable, Sendable {
  /// The submitted cross-site request forgery token is invalid.
  case invalidCSRF
  /// A required field is absent.
  case missing(String)
  /// A named field failed validation for the supplied reason.
  case invalid(String, reason: String)

  /// The field identifier used to link an error summary to its native control.
  public var fieldName: String? {
    switch self {
    case .invalidCSRF: nil
    case .missing(let name), .invalid(let name, _): name.isEmpty ? nil : name
    }
  }

  /// A user-facing description suitable for an inline error or error summary.
  public var message: String {
    switch self {
    case .invalidCSRF: "Reload this page and submit the form again."
    case .missing: "Enter a value for this field."
    case .invalid(_, let reason): reason
    }
  }
}

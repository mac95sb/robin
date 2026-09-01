import Foundation
import RobinHTML

/// Decodes signup forms from supported transport representations.
public enum FormDecoder {
  /// Decodes and validates a URL-encoded HTML form submission.
  ///
  /// - Parameters:
  ///   - body: The `application/x-www-form-urlencoded` request body.
  ///   - csrfToken: The token submitted with the form.
  ///   - expectedCSRFToken: The token required for the submission.
  /// - Returns: A validated signup form.
  /// - Throws: ``FieldValidationError/invalidCSRF`` when the token differs, or another
  ///   ``FieldValidationError`` when a required field is missing or invalid.
  public static func decodeHTMLForm(
    _ body: String,
    csrfToken: String,
    expectedCSRFToken: String
  ) throws -> SignupForm {
    guard csrfToken == expectedCSRFToken else { throw FieldValidationError.invalidCSRF }
    var fields: [String: String] = [:]
    for pair in body.split(separator: "&") {
      let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
      guard parts.count == 2 else { continue }
      fields[parts[0]] = parts[1].replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }
    guard let email = fields["email"] else { throw FieldValidationError.missing("email") }
    guard let displayName = fields["displayName"] else {
      throw FieldValidationError.missing("displayName")
    }
    return try SignupForm(email: email, displayName: displayName).validated()
  }

  /// Decodes and validates a JSON API submission.
  ///
  /// - Parameter data: JSON matching ``SignupForm``.
  /// - Returns: A validated signup form.
  public static func decodeJSON(_ data: Data) throws -> SignupForm {
    try JSONDecoder().decode(SignupForm.self, from: data).validated()
  }

  /// Renders an accessible HTML form for clients without the Robin runtime.
  ///
  /// The markup uses a `label` for each field and includes the CSRF token as a
  /// hidden input. All interpolated values are HTML-escaped.
  ///
  /// - Parameters:
  ///   - action: The URL that receives the form submission.
  ///   - csrfToken: The CSRF token included in the submission.
  /// - Returns: The escaped HTML for the form.
  public static func renderFallbackHTML(action: String, csrfToken: String) -> String {
    #"<form action="\#(HTMLRenderer.escape(action))" method="post"><input name="csrf" type="hidden" value="\#(HTMLRenderer.escape(csrfToken))"><label for="email">Email</label><input id="email" name="email" required type="email"><button type="submit">Submit</button></form>"#
  }
}

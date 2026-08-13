import Foundation

/// An error produced while decoding or validating submitted form fields.
public enum FieldValidationError: Error, Equatable, Sendable {
  case invalidCSRF
  case missing(String)
  case invalid(String, reason: String)
}

/// Associates a stable form-field name with a codable value.
@propertyWrapper
public struct Field<Value: Codable & Sendable>: Sendable {
  public let name: String
  public var wrappedValue: Value

  public init(wrappedValue: Value, _ name: String) {
    self.name = name
    self.wrappedValue = wrappedValue
  }

  public var projectedValue: Field<Value> { self }
}

/// An uploaded file represented by its metadata and bytes.
public struct FileField: Equatable, Sendable {
  public let filename: String
  public let mediaType: String
  public let bytes: [UInt8]

  public init(filename: String, mediaType: String, bytes: [UInt8]) {
    self.filename = filename
    self.mediaType = mediaType
    self.bytes = bytes
  }
}

/// The shared schema used to validate signup submissions.
public struct SignupForm: Codable, Equatable, Sendable {
  public var email: String
  public var displayName: String

  public init(email: String, displayName: String) {
    self.email = email
    self.displayName = displayName
  }

  /// Returns the form after validating all fields.
  ///
  /// - Throws: A ``FieldValidationError`` describing the first invalid field.
  public func validated() throws(FieldValidationError) -> Self {
    guard email.contains("@") else { throw .invalid("email", reason: "must contain @") }
    guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
      throw .invalid("displayName", reason: "must not be empty")
    }
    return self
  }
}

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
  /// - Parameters:
  ///   - action: The URL that receives the form submission.
  ///   - csrfToken: The CSRF token included in the submission.
  public static func renderFallbackHTML(action: String, csrfToken: String) -> String {
    #"<form action="\#(HTMLRenderer.escape(action))" method="post"><input name="csrf" type="hidden" value="\#(HTMLRenderer.escape(csrfToken))"><label for="email">Email</label><input id="email" name="email" required type="email"><button type="submit">Submit</button></form>"#
  }
}

/// Produces a stable `form.`-prefixed name from a string literal.
///
/// - Parameter name: A plain string literal containing the field name.
/// - Returns: The field name prefixed with `form.`.
@freestanding(expression)
public macro generatedFieldName(_ name: String) -> String =
  #externalMacro(module: "RobinMacros", type: "FieldNameMacro")

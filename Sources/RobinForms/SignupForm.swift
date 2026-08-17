import Foundation

/// The shared schema used to validate signup submissions.
public struct SignupForm: Codable, Equatable, Sendable {
  /// The submitter's email address.
  public var email: String

  /// The submitter's display name.
  public var displayName: String

  /// Creates a signup form.
  ///
  /// - Parameters:
  ///   - email: The submitter's email address.
  ///   - displayName: The submitter's display name.
  public init(email: String, displayName: String) {
    self.email = email
    self.displayName = displayName
  }

  /// Returns the form after validating all fields.
  ///
  /// - Returns: The form, unchanged, when every field is valid.
  /// - Throws: A ``FieldValidationError`` describing the first invalid field.
  public func validated() throws(FieldValidationError) -> Self {
    guard email.contains("@") else { throw .invalid("email", reason: "must contain @") }
    guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
      throw .invalid("displayName", reason: "must not be empty")
    }
    return self
  }
}

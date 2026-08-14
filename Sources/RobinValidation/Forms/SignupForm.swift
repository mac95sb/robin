import Foundation

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

import RobinHTML

/// Linked validation errors displayed above a redisplayed form without requiring JavaScript.
public struct FormErrorSummary: Component {
  private let errors: [FieldValidationError]

  /// Creates a summary from a decoded form's validation errors.
  public init(_ errors: [FieldValidationError]) { self.errors = errors }

  /// A heading and linked errors, omitted when the form is valid.
  public var body: ComponentContent {
    if !errors.isEmpty {
      Section {
        Heading(.two) { "Check the form" }
        for error in errors {
          if let name = error.fieldName {
            Link("#\(name)") { "\(name): \(error.message)" }
          } else {
            Text { error.message }
          }
        }
      }
    }
  }
}

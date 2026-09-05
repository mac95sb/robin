/// A reusable submitted-value model whose field declarations also render native controls.
///
/// Apply ``FormModel()`` to a structure with default-valued ``Field`` properties to synthesize
/// decoding and error collection. Use `RobinHTML.Form` as the submission container.
public protocol Form: Sendable {
  /// Creates the model with its field declarations and default values.
  init()
  /// Applies submitted values to every declared field, retaining invalid text for redisplay.
  mutating func decodeFields(from values: FormValues)
  /// Validation errors in declaration order.
  var validationErrors: [FieldValidationError] { get }
}

extension Form {
  /// Decodes submitted fields into a model that can be redisplayed with inline errors.
  public static func decode(from values: FormValues) -> Self {
    var form = Self()
    form.decodeFields(from: values)
    return form
  }

  /// Returns the model only when every declared field passed validation.
  ///
  /// Call this before performing mutations. Inspect ``validationErrors`` to display all errors.
  public func validated() throws -> Self {
    if let error = validationErrors.first { throw error }
    return self
  }
}

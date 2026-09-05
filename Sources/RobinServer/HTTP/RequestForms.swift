import Foundation
import RobinForms

extension Request {
  /// Decodes a declared form from URL-encoded, multipart, or JSON input.
  ///
  /// Apply security middleware before this method to enforce origin/CSRF policy. This method
  /// bounds input and applies the same field validation for every transport. Call `validated()`
  /// on the returned model before persisting it; otherwise redisplay its values and errors.
  ///
  /// - Parameters:
  ///   - type: The declared form model.
  ///   - maximumBytes: The maximum accepted body and individual upload size.
  ///   - maximumFields: The maximum submitted field count.
  /// - Throws: A parsing or field error for unsupported, oversized, duplicate, or malformed input.
  public func form<Model: RobinForms.Form>(
    _ type: Model.Type, maximumBytes: Int = 1_048_576, maximumFields: Int = 100
  ) throws -> Model {
    guard maximumBytes >= 0, maximumFields > 0, body.count <= maximumBytes else {
      throw FieldValidationError.invalid("", reason: "The submitted form is too large.")
    }
    let contentType = header(.contentType)?.split(separator: ";", maxSplits: 1).first?
      .trimmingCharacters(in: .whitespaces).lowercased()
    let values: FormValues
    switch contentType {
    case "application/x-www-form-urlencoded":
      values = try .urlEncoded(body, maximumBytes: maximumBytes, maximumFields: maximumFields)
    case "application/json":
      values = try .json(body, maximumBytes: maximumBytes, maximumFields: maximumFields)
    case "multipart/form-data":
      var fields: [String: FormValues.Value] = [:]
      for part in try MultipartFormData.parse(
        self, maximumParts: maximumFields, maximumPartBytes: maximumBytes)
      {
        guard !part.name.isEmpty, fields[part.name] == nil else {
          throw FieldValidationError.invalid(
            "", reason: "Duplicate or unnamed form fields are not allowed.")
        }
        if let filename = part.filename {
          fields[part.name] = .file(
            .init(
              filename: filename,
              mediaType: part.headers["content-type"] ?? "application/octet-stream",
              bytes: part.body))
        } else if let text = String(bytes: part.body, encoding: .utf8) {
          fields[part.name] = .text(text)
        } else {
          throw FieldValidationError.invalid(part.name, reason: "Enter valid UTF-8 text.")
        }
      }
      values = FormValues(fields)
    default:
      throw FieldValidationError.invalid("", reason: "Submit a native form or a JSON object.")
    }
    return Model.decode(from: values)
  }
}

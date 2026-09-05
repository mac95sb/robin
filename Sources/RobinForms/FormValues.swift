import Foundation

/// Bounded transport values decoded before applying a form's field declarations.
public struct FormValues: Sendable {
  /// A submitted text, JSON, or uploaded file value.
  public enum Value: Sendable {
    /// A decoded native form value.
    case text(String)
    /// One encoded JSON value, retaining its original scalar type.
    case json(Data)
    /// An uploaded file and its untrusted metadata.
    case file(FileField)
  }

  /// Values indexed by stable field name.
  public let fields: [String: Value]

  /// Creates values already decoded and bounded by a transport adapter.
  public init(_ fields: [String: Value]) { self.fields = fields }

  /// Decodes a bounded URL-encoded body, rejecting duplicate fields and invalid UTF-8 or escapes.
  public static func urlEncoded(
    _ bytes: [UInt8], maximumBytes: Int = 1_048_576, maximumFields: Int = 100
  ) throws -> Self {
    guard bytes.count <= maximumBytes, let body = String(bytes: bytes, encoding: .utf8) else {
      throw FieldValidationError.invalid(
        "", reason: "The submitted form is too large or malformed.")
    }
    var fields: [String: Value] = [:]
    if body.isEmpty { return Self(fields) }
    for field in body.split(separator: "&", omittingEmptySubsequences: false) {
      let pair = field.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      guard fields.count < maximumFields,
        let name = String(pair[0]).replacingOccurrences(of: "+", with: " ").removingPercentEncoding,
        !name.isEmpty, fields[name] == nil,
        let value = (pair.count == 2 ? String(pair[1]) : "")
          .replacingOccurrences(of: "+", with: " ").removingPercentEncoding
      else { throw FieldValidationError.invalid("", reason: "The submitted form is malformed.") }
      fields[name] = .text(value)
    }
    return Self(fields)
  }

  /// Decodes a bounded JSON object without coercing JSON strings into numbers or booleans.
  public static func json(
    _ bytes: [UInt8], maximumBytes: Int = 1_048_576, maximumFields: Int = 100
  ) throws -> Self {
    guard bytes.count <= maximumBytes,
      let object = (try? JSONSerialization.jsonObject(with: Data(bytes))) as? [String: Any],
      object.count <= maximumFields
    else { throw FieldValidationError.invalid("", reason: "A bounded JSON object is required.") }
    return Self(
      try object.mapValues {
        .json(
          try JSONSerialization.data(withJSONObject: $0, options: [.fragmentsAllowed, .sortedKeys]))
      })
  }
}

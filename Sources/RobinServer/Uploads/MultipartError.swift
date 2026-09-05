import HTTPTypes

/// Errors produced while validating multipart form data.
public enum MultipartError: Error, Equatable, Sendable {
  /// The request has no multipart content type.
  case contentTypeRequired
  /// The content type has no boundary parameter.
  case boundaryRequired
  /// The multipart body or part headers are malformed.
  case malformed
  /// The body contains more than the configured number of parts.
  case tooManyParts
  /// A part exceeds the configured byte limit.
  case partTooLarge
}

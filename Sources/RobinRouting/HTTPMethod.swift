/// An HTTP method supported by Robin API routes.
public enum HTTPMethod: String, Equatable, Sendable {
  /// Retrieves a representation.
  case get
  /// Creates or submits a representation.
  case post
  /// Replaces a representation.
  case put
  /// Partially updates a representation.
  case patch
  /// Deletes a representation.
  case delete
}

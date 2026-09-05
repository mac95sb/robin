import HTTPTypes

/// The response representation preferred by a typed server error.
public enum ServerErrorRepresentation: Equatable, Sendable {
  /// Negotiate from the request's `Accept` field.
  case automatic
  /// Return a JSON error object.
  case json
  /// Return plain text.
  case text
}

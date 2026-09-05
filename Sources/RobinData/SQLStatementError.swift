/// Errors raised while constructing database-neutral SQL.
public enum SQLStatementError: Error, Equatable, Sendable {
  /// An identifier contained unsupported characters.
  case invalidIdentifier(String)
}

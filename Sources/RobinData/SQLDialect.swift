/// The SQL dialect used to render a statement.
public enum SQLDialect: Equatable, Sendable {
  /// SQLite SQL with question-mark bindings.
  case sqlite
  /// PostgreSQL SQL with numbered bindings.
  case postgres
}

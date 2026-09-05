import NIOCore
import SQLiteNIO

/// SQLite database lifecycle errors.
public enum SQLiteDatabaseError: Error, Equatable, Sendable {
  /// The database has already shut down.
  case closed
  /// Persistent databases require an absolute path.
  case relativePath(String)
}

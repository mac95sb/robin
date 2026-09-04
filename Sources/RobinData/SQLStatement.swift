import Foundation

/// The SQL dialect used to render a statement.
public enum SQLDialect: Equatable, Sendable {
  /// SQLite SQL with question-mark bindings.
  case sqlite
  /// PostgreSQL SQL with numbered bindings.
  case postgres
}

/// A safe SQL identifier.
public struct SQLIdentifier: Hashable, Sendable {
  /// The unquoted identifier.
  public let value: String

  /// Creates an identifier containing letters, digits, or underscores.
  ///
  /// The first character must be a letter or underscore.
  public init(_ value: String) throws {
    guard let first = value.unicodeScalars.first,
      first == "_" || CharacterSet.letters.contains(first),
      value.unicodeScalars.allSatisfy({ $0 == "_" || CharacterSet.alphanumerics.contains($0) })
    else { throw SQLStatementError.invalidIdentifier(value) }
    self.value = value
  }
}

/// Errors raised while constructing database-neutral SQL.
public enum SQLStatementError: Error, Equatable, Sendable {
  /// An identifier contained unsupported characters.
  case invalidIdentifier(String)
}

/// A database-neutral SQL statement with typed bindings.
public struct SQLStatement: ExpressibleByStringInterpolation, ExpressibleByStringLiteral, Sendable {
  enum Part: Sendable {
    case sql(String)
    case identifier(SQLIdentifier)
    case binding(DatabaseValue)
  }

  let parts: [Part]

  /// Creates an unbound SQL statement.
  public init(stringLiteral value: String) { parts = [.sql(value)] }

  /// Creates a statement from interpolated SQL parts.
  public init(stringInterpolation: StringInterpolation) { parts = stringInterpolation.parts }

  /// Renders SQL and bindings for an adapter.
  public func render(for dialect: SQLDialect) -> (sql: String, bindings: [DatabaseValue]) {
    var sql = ""
    var bindings: [DatabaseValue] = []
    for part in parts {
      switch part {
      case .sql(let value):
        sql += value
      case .identifier(let identifier):
        sql += "\"\(identifier.value)\""
      case .binding(let value):
        bindings.append(value)
        sql += dialect == .sqlite ? "?" : "$\(bindings.count)"
      }
    }
    return (sql, bindings)
  }

  /// Builds statement parts using Swift string interpolation.
  public struct StringInterpolation: StringInterpolationProtocol, Sendable {
    var parts: [Part] = []

    /// Creates interpolation storage with estimated capacities.
    public init(literalCapacity: Int, interpolationCount: Int) {
      parts.reserveCapacity(interpolationCount * 2 + 1)
    }

    /// Appends trusted SQL syntax from the literal source string.
    public mutating func appendLiteral(_ literal: String) { parts.append(.sql(literal)) }
    /// Appends a safely quoted identifier.
    public mutating func appendInterpolation(_ identifier: SQLIdentifier) {
      parts.append(.identifier(identifier))
    }
    /// Appends a typed bound value.
    public mutating func appendInterpolation(_ value: DatabaseValue) {
      parts.append(.binding(value))
    }
    /// Appends bound text.
    public mutating func appendInterpolation(_ value: String) {
      parts.append(.binding(.text(value)))
    }
    /// Appends a bound platform integer.
    public mutating func appendInterpolation(_ value: Int) {
      parts.append(.binding(.integer(Int64(value))))
    }
    /// Appends a bound 64-bit integer.
    public mutating func appendInterpolation(_ value: Int64) {
      parts.append(.binding(.integer(value)))
    }
    /// Appends a bound floating-point value.
    public mutating func appendInterpolation(_ value: Double) {
      parts.append(.binding(.real(value)))
    }
    /// Appends a bound Boolean value.
    public mutating func appendInterpolation(_ value: Bool) {
      parts.append(.binding(.boolean(value)))
    }
  }
}

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

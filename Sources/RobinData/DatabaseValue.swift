import Foundation

/// A database-neutral scalar value used by queries and rows.
public enum DatabaseValue: Equatable, Sendable {
  /// SQL `NULL`.
  case null
  /// A signed 64-bit integer.
  case integer(Int64)
  /// A double-precision number.
  case real(Double)
  /// UTF-8 text.
  case text(String)
  /// Arbitrary bytes.
  case blob(Data)
  /// A Boolean value.
  case boolean(Bool)
}

extension DatabaseValue {
  /// Returns the integer value, if this value has integer storage.
  public var integer: Int64? {
    guard case .integer(let value) = self else { return nil }
    return value
  }

  /// Returns the floating-point value, if this value has real storage.
  public var double: Double? {
    guard case .real(let value) = self else { return nil }
    return value
  }

  /// Returns the text value, if this value has text storage.
  public var string: String? {
    guard case .text(let value) = self else { return nil }
    return value
  }

  /// Returns the bytes, if this value has blob storage.
  public var data: Data? {
    guard case .blob(let value) = self else { return nil }
    return value
  }
}

extension DatabaseValue: ExpressibleByNilLiteral {
  /// Creates a null database value.
  public init(nilLiteral: ()) { self = .null }
}

extension DatabaseValue: ExpressibleByIntegerLiteral {
  /// Creates an integer database value.
  public init(integerLiteral value: Int64) { self = .integer(value) }
}

extension DatabaseValue: ExpressibleByFloatLiteral {
  /// Creates a floating-point database value.
  public init(floatLiteral value: Double) { self = .real(value) }
}

extension DatabaseValue: ExpressibleByStringLiteral {
  /// Creates a text database value.
  public init(stringLiteral value: String) { self = .text(value) }
}

extension DatabaseValue: ExpressibleByBooleanLiteral {
  /// Creates a Boolean database value.
  public init(booleanLiteral value: Bool) { self = .boolean(value) }
}

/// A typed path-segment codec used for route matching and reverse routing.
///
/// Decoding receives one percent-decoded path segment and can reject it by returning `nil`.
/// Encoding produces an unescaped segment, which ``Route/url(for:)`` percent-encodes when it
/// constructs a URL.
public struct PathParameter<Value: Sendable>: Sendable {
  /// The parameter name used by route metadata and diagnostics.
  public let name: String
  private let decodeValue: @Sendable (String) -> Value?
  private let encodeValue: @Sendable (Value) -> String

  /// Creates a named path parameter with custom conversion closures.
  ///
  /// The decoder and encoder should describe inverse representations whenever possible so a
  /// value can be generated into a URL and matched back to the same value.
  ///
  /// - Parameters:
  ///   - name: The parameter name used by route metadata and diagnostics.
  ///   - decode: A closure that converts a percent-decoded segment to a typed value, or returns
  ///     `nil` when the segment is invalid.
  ///   - encode: A closure that converts a typed value to an unescaped path segment.
  ///
  /// > Note: Do not percent-encode the value returned by `encode`; URL generation performs
  /// > canonical segment encoding after this closure returns.
  public init(
    name: String,
    decode: @escaping @Sendable (String) -> Value?,
    encode: @escaping @Sendable (Value) -> String
  ) {
    self.name = name
    self.decodeValue = decode
    self.encodeValue = encode
  }

  func decode(_ value: String) -> Value? { decodeValue(value) }
  func encode(_ value: Value) -> String { encodeValue(value) }
}

extension PathParameter where Value == String {
  /// Creates a path parameter that preserves the decoded segment as a string.
  ///
  /// - Parameter name: The parameter name used by route metadata and diagnostics.
  /// - Returns: A string parameter codec with identity decoding and encoding.
  public static func string(_ name: String) -> Self {
    .init(name: name, decode: { $0 }, encode: { $0 })
  }
}

extension PathParameter where Value == Int {
  /// Creates a path parameter that converts base-10 integer segments.
  ///
  /// Matching fails when Swift's integer parser cannot represent the decoded segment as an
  /// `Int`. Reverse routing uses the integer's standard decimal representation.
  ///
  /// - Parameter name: The parameter name used by route metadata and diagnostics.
  /// - Returns: A base-10 integer parameter codec.
  public static func integer(_ name: String) -> Self {
    .init(name: name, decode: Int.init, encode: String.init)
  }
}

/// The conformance synthesized by ``ColorTokenSet()``.
public protocol ColorTokenSetDefinition:
  CaseIterable, Hashable, RawRepresentable, Sendable
where RawValue == String {}

extension ColorTokenSetDefinition {
  /// The stable theme identity for this token case.
  public var colorToken: ColorToken {
    ColorToken(rawValue: "\(String(reflecting: Self.self)).\(rawValue)")
  }

  /// Converts a complete typed registration into the theme's color-token representation.
  public static func register(_ values: [Self: Color]) throws -> [ColorToken: Color] {
    let missing = allCases.filter { values[$0] == nil }
    guard missing.isEmpty else {
      throw ColorTokenSetError.missingTokens(missing.map(\.rawValue).sorted())
    }
    return Dictionary(uniqueKeysWithValues: values.map { ($0.key.colorToken, $0.value) })
  }
}

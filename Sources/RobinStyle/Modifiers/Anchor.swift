/// A typed anchor name used by native CSS anchor positioning.
public struct Anchor: Equatable, Hashable, Sendable {
  let cssName: String

  /// Creates an anchor from an ASCII identifier. Robin supplies the required CSS prefix.
  public init(_ identifier: String) throws {
    self.cssName = try cssCustomIdentifier(identifier)
  }
}

func cssCustomIdentifier(_ identifier: String) throws -> String {
  let allowed = identifier.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
  guard allowed, identifier.first?.isLetter == true else {
    throw AdvancedStyleError.invalidIdentifier(identifier)
  }
  return "--r-\(identifier)"
}

/// A collection of typed style declarations.
public struct TypedStyle: Equatable, Hashable, Sendable {
  public let declarations: [StyleDeclaration]

  public init(_ declarations: [StyleDeclaration]) {
    self.declarations = declarations
  }

  var normalized: [StyleDeclaration] {
    var values: [StyleProperty: String] = [:]
    for declaration in declarations { values[declaration.property] = declaration.value }
    return values.map(StyleDeclaration.init).sorted { $0.property < $1.property }
  }
}

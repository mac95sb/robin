/// A collection of typed style declarations.
///
/// A style groups ``StyleDeclaration`` values that are compiled into a single
/// CSS class by ``TypedCSSCompiler``.
public struct TypedStyle: Equatable, Hashable, Sendable {
  /// The style's declarations, in declaration order.
  public let declarations: [StyleDeclaration]

  /// Creates a typed style.
  ///
  /// - Parameter declarations: The style's declarations.
  public init(_ declarations: [StyleDeclaration]) {
    self.declarations = declarations
  }

  /// The declarations with later values winning per property, sorted by property.
  var normalized: [StyleDeclaration] {
    var values: [StyleProperty: String] = [:]
    for declaration in declarations { values[declaration.property] = declaration.value }
    return values.map(StyleDeclaration.init).sorted { $0.property < $1.property }
  }
}

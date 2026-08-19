/// A collection of typed style declarations.
///
/// A style groups ``StyleDeclaration`` values that are compiled into a single
/// CSS class by ``TypedCSSCompiler``. Each `TypedStyle` compiles to its own generated class, so
/// passing a component's base style and a composition-time instance override as separate
/// `TypedStyle` values keeps their generated selectors isolated from one another.
public struct TypedStyle: Equatable, Hashable, Sendable {
  /// The style's declarations, in declaration order.
  public let declarations: [StyleDeclaration]

  /// The cascade condition under which the declarations apply.
  public let condition: StyleCondition

  /// Whether an ancestor in the current prototype context declared containment, required for
  /// ``StyleCondition/containerMinWidth(_:)`` to lower safely to `@container`.
  public let containmentContext: ContainmentContext

  /// Creates a typed style.
  ///
  /// - Parameters:
  ///   - declarations: The style's declarations.
  ///   - condition: The cascade condition under which the declarations apply. The default is
  ///     ``StyleCondition/always``.
  ///   - containmentContext: Whether an ancestor declared containment. The default is
  ///     ``ContainmentContext/none``.
  public init(
    _ declarations: [StyleDeclaration],
    condition: StyleCondition = .always,
    containmentContext: ContainmentContext = .none
  ) {
    self.declarations = declarations
    self.condition = condition
    self.containmentContext = containmentContext
  }

  /// The declarations with later values winning per property, sorted by property.
  var normalized: [StyleDeclaration] {
    var values: [StyleProperty: String] = [:]
    for declaration in declarations { values[declaration.property] = declaration.value }
    return values.map(StyleDeclaration.init).sorted { $0.property < $1.property }
  }
}

@_spi(Rendering) import RobinCore
@_spi(Rendering) import RobinHTML

/// Deterministic class assignments and CSS compiled from reachable Render IR styles.
public struct CompiledStyles: Equatable, Sendable {
  struct Assignment: Equatable, Sendable {
    let signature: [StyleDeclaration]
    let className: String
  }

  let assignments: [Assignment]

  /// The emitted stylesheet containing all compiled style rules.
  public var css: String { documentCSS + rulesCSS }

  /// Document-wide defaults emitted once when assembling stylesheet chunks.
  @_spi(Rendering) public let documentCSS: String

  /// Reachable component rules, keyframes, and view-transition declarations.
  @_spi(Rendering) public let rulesCSS: String
}

@_spi(Rendering)
extension CompiledStyles {
  /// Finds the generated class name for a style signature.
  public func className(for styles: [StyleDeclaration]) -> String? {
    assignments.first { $0.signature == StyleCompiler.normalized(styles) }?.className
  }
}

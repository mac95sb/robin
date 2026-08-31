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
  public let css: String
}

@_spi(Rendering)
extension CompiledStyles: RobinHTML.StyleClassResolving {
  /// Finds the generated class name for a style signature.
  public func className(for styles: [StyleDeclaration]) -> String? {
    assignments.first { $0.signature == StyleCompiler.normalized(styles) }?.className
  }
}

import RobinCore

/// Resolves opaque style declarations to generated HTML class names.
@_spi(Rendering)
public protocol StyleClassResolving: Sendable {
  /// Returns the generated class name for an exact declaration signature.
  ///
  /// - Parameter declarations: The declarations attached to one rendered element.
  /// - Returns: The matching class name, or `nil` when the signature was not compiled.
  func className(for declarations: [StyleDeclaration]) -> String?
}

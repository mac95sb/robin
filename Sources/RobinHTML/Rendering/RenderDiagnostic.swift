@_spi(Rendering) import RobinCore

/// A typed structural validation failure discovered before HTML emission.
///
/// Diagnostics are reported in deterministic depth-first traversal order.
public enum RenderDiagnostic: Error, Equatable, Sendable {
  /// An element contains more than one attribute with the same serialized name.
  ///
  /// - Parameters:
  ///   - element: The kind of element containing the duplicate attribute.
  ///   - name: The serialized HTML attribute name that occurs more than once.
  case duplicateAttribute(element: RenderElement.Kind, name: String)

  /// A button contains a nested button or input control.
  case interactiveElementNestedInButton

  /// An element has style declarations that cannot be mapped to a generated class name.
  ///
  /// - Parameter element: The kind of element whose declarations could not be resolved.
  case unresolvedStyleDeclarations(element: RenderElement.Kind)
}

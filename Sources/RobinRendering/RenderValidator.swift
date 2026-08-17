/// Validates the structure of a render tree.
///
/// The validator walks a ``RenderNode`` tree and reports every
/// ``RenderDiagnostic`` it finds: duplicate attributes, interactive elements
/// nested inside a `button`, and embeds without an `https://` origin.
public enum RenderValidator {
  /// Validates a render tree and returns all diagnostics found.
  ///
  /// Validation is nonfatal: the walk continues after each problem so callers
  /// receive the complete list.
  ///
  /// - Parameter node: The root of the render tree to validate.
  /// - Returns: Every diagnostic found, in depth-first order. An empty array
  ///   means the tree is valid.
  public static func validate(_ node: RenderNode) -> [RenderDiagnostic] {
    var diagnostics: [RenderDiagnostic] = []
    walk(node, insideButton: false, diagnostics: &diagnostics)
    return diagnostics
  }

  private static func walk(
    _ node: RenderNode,
    insideButton: Bool,
    diagnostics: inout [RenderDiagnostic]
  ) {
    switch node {
    case .text:
      return
    case .fragment(let children):
      for child in children { walk(child, insideButton: insideButton, diagnostics: &diagnostics) }
    case .embed(let embed):
      if !embed.source.hasPrefix("https://") {
        diagnostics.append(.invalidEmbedOrigin(embed.source))
      }
    case .element(let element):
      var seen = Set<String>()
      for attribute in element.attributes where !seen.insert(attribute.name).inserted {
        diagnostics.append(.duplicateAttribute(element: element.name, name: attribute.name))
      }
      if insideButton && (element.name == .button || element.name == .input) {
        diagnostics.append(.interactiveElementNestedInButton)
      }
      for child in element.children {
        walk(
          child, insideButton: insideButton || element.name == .button, diagnostics: &diagnostics)
      }
    }
  }
}

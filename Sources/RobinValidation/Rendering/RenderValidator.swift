public enum RenderValidator {
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

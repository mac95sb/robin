@_spi(Rendering) import RobinCore

/// Validates resolved component trees before rendering.
struct RenderValidator {
  /// Finds every structural validation failure in a resolved component tree.
  ///
  /// - Parameter root: The root render node to inspect.
  /// - Returns: All diagnostics in deterministic depth-first traversal order, or an empty array
  ///   when the tree is valid.
  static func validate(_ root: RenderNode) -> [RenderDiagnostic] {
    var diagnostics: [RenderDiagnostic] = []
    walk(root, insideButton: false, diagnostics: &diagnostics)
    return diagnostics
  }

  private static func walk(
    _ node: RenderNode,
    insideButton: Bool,
    diagnostics: inout [RenderDiagnostic]
  ) {
    switch node.renderingStorage {
    case .text: break
    case .fragment(let children):
      for child in children { walk(child, insideButton: insideButton, diagnostics: &diagnostics) }
    case .element(let element):
      var names = Set<String>()
      for attribute in element.attributes {
        let name = attribute.validationName
        if !names.insert(name).inserted {
          diagnostics.append(.duplicateAttribute(element: element.kind, name: name))
        }
        if case .sourceSet(let candidates) = attribute {
          diagnostics += candidates.compactMap {
            $0.width > 0 ? nil : .invalidResponsiveImageWidth($0.width)
          }
        }
      }
      if insideButton
        && (element.kind == .button || element.kind == .input || element.kind == .a
          || element.kind == .textarea)
      {
        diagnostics.append(.interactiveElementNestedInButton)
      }
      for child in element.children {
        walk(
          child, insideButton: insideButton || element.kind == .button, diagnostics: &diagnostics)
      }
    }
  }
}

extension RenderElement.Attribute {
  fileprivate var validationName: String {
    switch self {
    case .identifier: "id"
    case .buttonType, .inputType: "type"
    case .name: "name"
    case .value: "value"
    case .accessibilityLabel: "aria-label"
    case .href: "href"
    case .source: "src"
    case .sourceSet: "srcset"
    case .sizes: "sizes"
    case .alternateText: "alt"
    case .action: "action"
    case .formMethod: "method"
    case .labelFor: "for"
    case .open: "open"
    case .title: "title"
    case .sandbox: "sandbox"
    case .syntaxLanguage: "data-robin-language"
    case .syntaxTheme: "data-robin-highlight-theme"
    case .syntaxHighlight: "data-robin-highlight"
    case .accessibilityHidden: "aria-hidden"
    case .imageRole: "role"
    case .vectorX: "x"
    case .vectorY: "y"
    case .vectorWidth: "width"
    case .vectorHeight: "height"
    case .vectorCenterX: "cx"
    case .vectorCenterY: "cy"
    case .vectorRadius: "r"
    case .vectorRadiusX: "rx"
    case .vectorRadiusY: "ry"
    case .vectorX1: "x1"
    case .vectorY1: "y1"
    case .vectorX2: "x2"
    case .vectorY2: "y2"
    case .vectorPath: "d"
    case .vectorPoints: "points"
    case .vectorViewBox: "viewBox"
    case .vectorFill: "fill"
    case .vectorStroke: "stroke"
    case .vectorStrokeWidth: "stroke-width"
    case .vectorStrokeLineCap: "stroke-linecap"
    case .vectorStrokeLineJoin: "stroke-linejoin"
    }
  }
}

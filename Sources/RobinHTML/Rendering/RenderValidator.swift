import Foundation
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
        switch attribute {
        case .href(let value):
          if !safeURL(value, schemes: ["http", "https", "mailto", "tel"]) {
            diagnostics.append(.invalidURL(attribute: name, value: value))
          }
        case .action(let value):
          if !safeURL(value, schemes: ["http", "https"]) {
            diagnostics.append(.invalidURL(attribute: name, value: value))
          }
        default: break
        }
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
          || element.kind == .textarea || element.kind == .select)
      {
        diagnostics.append(.interactiveElementNestedInButton)
      }
      for child in element.children {
        walk(
          child, insideButton: insideButton || element.kind == .button, diagnostics: &diagnostics)
      }
    }
  }

  private static func safeURL(_ value: String, schemes: Set<String>) -> Bool {
    guard !value.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7F }),
      !value.contains("\\"),
      let components = URLComponents(string: value.trimmingCharacters(in: .whitespaces))
    else { return false }
    return components.scheme.map { schemes.contains($0.lowercased()) } ?? true
  }
}

extension RenderElement.Attribute {
  fileprivate var validationName: String {
    switch self {
    case .popover: "popover"
    case .popoverCommand: "command"
    case .languageLink: "data-robin-language-link"
    case .identifier: "id"
    case .buttonType, .inputType: "type"
    case .name: "name"
    case .value: "value"
    case .selected: "selected"
    case .appearanceChoice: "data-robin-appearance-choice"
    case .accessibilityPressed: "aria-pressed"
    case .appearancePicker: "data-robin-appearance-picker"
    case .appearanceState: "data-robin-appearance"
    case .languagePicker: "data-robin-language-picker"
    case .required: "required"
    case .minimumLength: "minlength"
    case .maximumLength: "maxlength"
    case .accessibilityDescribedBy: "aria-describedby"
    case .accessibilityInvalid: "aria-invalid"
    case .multipartEncoding: "enctype"
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
    case .hiddenNumberStepper: "data-robin-stepper-hidden"
    case .stateText: "data-robin-text"
    case .stateInput: "data-robin-input"
    case .stateHidden: "data-robin-hidden"
    case .stateDisabled: "data-robin-disabled"
    case .stateAction: "data-robin-action"
    case .stateOnChange: "data-robin-change"
    case .stateOnInput: "data-robin-edit"
    case .stateVisible: "data-robin-visible"
    case .tabs: "data-robin-tabs"
    case .tabControl: "tab control"
    case .tabLabel: "tab label"
    case .tabPanel: "data-robin-tab-panel"
    case .popoverTrigger: "popover trigger"
    case .popoverContent: "popover"
    case .popoverDismiss: "popover dismiss"
    case .hidden: "hidden"
    case .disabled: "disabled"
    case .checked: "checked"
    case .anyStep: "step"
    case .syntaxHighlight: "data-robin-highlight"
    case .accessibilityHidden: "aria-hidden"
    case .imageRole, .listRole: "role"
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

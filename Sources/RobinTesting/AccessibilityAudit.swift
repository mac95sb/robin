@_spi(Rendering) import RobinHTML

/// One accessibility problem found in a typed component tree.
public struct AccessibilityFinding: Equatable, Sendable {
  /// A stable machine-readable finding identifier.
  public let code: String
  /// A concise description of the problem.
  public let message: String

  /// Creates an accessibility finding.
  ///
  /// - Parameters:
  ///   - code: A stable machine-readable identifier.
  ///   - message: A concise description of the problem.
  public init(code: String, message: String) {
    self.code = code
    self.message = message
  }
}

/// Audits accessibility properties already represented by Robin's typed render tree.
public struct AccessibilityAudit {
  /// Audits a component for accessible names, landmarks, and heading order.
  ///
  /// - Parameter component: The component tree to inspect.
  /// - Returns: Findings in document order.
  public static func audit<ComponentType: Component>(_ component: ComponentType)
    -> [AccessibilityFinding]
  {
    audit(component.body)
  }

  /// Audits already-built component content.
  ///
  /// - Parameter content: The typed content to inspect.
  /// - Returns: Findings in document order.
  public static func audit(_ content: ComponentContent) -> [AccessibilityFinding] {
    let root = RenderNode.fragment(content.nodes)
    var mainCount = 0
    var previousHeading = 0
    var findings: [AccessibilityFinding] = []
    walk(root) { element in
      if element.kind == .main { mainCount += 1 }
      if let level = headingLevel(element.kind) {
        if previousHeading != 0, level > previousHeading + 1 {
          findings.append(
            .init(code: "heading-level-skip", message: "Heading levels must not skip ranks."))
        }
        previousHeading = level
      }
      if element.kind == .button,
        !hasNonemptyAccessibilityLabel(element),
        !containsText(element.children)
      {
        findings.append(
          .init(code: "button-name", message: "A button needs text or an accessibility label."))
      }
      if element.kind == .iframe,
        !element.attributes.contains(where: {
          if case .title(let value) = $0 { return value.contains { !$0.isWhitespace } }
          return false
        })
      {
        findings.append(
          .init(code: "embed-title", message: "An embedded document needs a nonempty title."))
      }
    }
    if mainCount > 1 {
      findings.append(
        .init(
          code: "multiple-main-landmarks", message: "A document can contain only one main landmark."
        ))
    }
    return findings
  }

  private static func walk(_ node: RenderNode, visit: (RenderElement) -> Void) {
    switch node.renderingStorage {
    case .text: break
    case .fragment(let children):
      for child in children { walk(child, visit: visit) }
    case .element(let element):
      visit(element)
      for child in element.children { walk(child, visit: visit) }
    }
  }

  private static func containsText(_ nodes: [RenderNode]) -> Bool {
    nodes.contains { node in
      switch node.renderingStorage {
      case .text(let value): value.contains { !$0.isWhitespace }
      case .fragment(let children): containsText(children)
      case .element(let element): containsText(element.children)
      }
    }
  }

  private static func hasNonemptyAccessibilityLabel(_ element: RenderElement) -> Bool {
    element.attributes.contains {
      if case .accessibilityLabel(let value) = $0 { return value.contains { !$0.isWhitespace } }
      return false
    }
  }

  private static func headingLevel(_ kind: RenderElement.Kind) -> Int? {
    switch kind {
    case .h1: 1
    case .h2: 2
    case .h3: 3
    case .h4: 4
    case .h5: 5
    case .h6: 6
    default: nil
    }
  }
}

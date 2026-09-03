import Foundation
@_spi(Rendering) import RobinCore

/// Deterministically validates and serializes render structures as escaped HTML.
///
/// The renderer escapes text and attribute values, orders attributes consistently, and can map
/// compiled style declarations to generated class names.
public struct HTMLRenderer {
  /// Validates and renders a resolved component tree without style declarations.
  ///
  /// Validation completes before serialization. If the tree has multiple diagnostics, this
  /// method throws the first diagnostic in deterministic traversal order. A styled element also
  /// throws because rendering it without a generated class would silently discard its styles.
  ///
  /// - Parameter root: The root render node to validate and serialize.
  /// - Returns: The escaped HTML representation of `root`.
  /// - Throws: A ``RenderDiagnostic`` when structural validation fails or styles are unresolved.
  public static func render(_ root: RenderNode) throws -> String {
    try render(root, styleResolver: nil)
  }

  /// Resolves, validates, and renders a component without style declarations.
  ///
  /// - Parameter component: The component to resolve and serialize.
  /// - Returns: The escaped HTML representation of `component`.
  /// - Throws: A ``RenderDiagnostic`` when validation fails or styles are unresolved.
  public static func render<C: Component>(_ component: C) throws -> String {
    try render(.fragment(component.body.nodes))
  }

  /// Validates and renders a resolved component tree using generated style-class assignments.
  ///
  /// - Parameters:
  ///   - root: The root render node to validate and serialize.
  ///   - styles: The resolver for generated class names.
  /// - Returns: The escaped HTML representation of `root`.
  /// - Throws: A ``RenderDiagnostic`` when validation fails or a style signature has no match.
  @_spi(Rendering)
  public static func render(
    _ root: RenderNode,
    styles: @escaping @Sendable ([StyleDeclaration]) -> String?
  ) throws -> String {
    try render(root, styleResolver: styles)
  }

  /// Resolves, validates, and renders a component using generated style-class assignments.
  ///
  /// - Parameters:
  ///   - component: The component to resolve and serialize.
  ///   - styles: The resolver for generated class names.
  /// - Returns: The escaped HTML representation of `component`.
  /// - Throws: A ``RenderDiagnostic`` when validation fails or a style signature has no match.
  @_spi(Rendering)
  public static func render<C: Component>(
    _ component: C,
    styles: @escaping @Sendable ([StyleDeclaration]) -> String?
  ) throws -> String {
    try render(.fragment(component.body.nodes), styles: styles)
  }

  /// Escapes a string for an HTML text or double-quoted attribute context.
  ///
  /// Ampersands, angle brackets, quotation marks, and apostrophes are replaced with HTML
  /// entities.
  ///
  /// - Parameter value: The unescaped string.
  /// - Returns: An HTML-safe representation of `value`.
  public static func escape(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&#39;")
  }

  /// Finds every structural validation failure in a resolved component tree.
  ///
  /// - Parameter root: The root render node to inspect.
  /// - Returns: All diagnostics in deterministic depth-first traversal order, or an empty array
  ///   when the tree is valid.
  public static func validate(_ root: RenderNode) -> [RenderDiagnostic] {
    RenderValidator.validate(root)
  }

  private static func render(
    _ root: RenderNode,
    styleResolver: (@Sendable ([StyleDeclaration]) -> String?)?
  ) throws -> String {
    let diagnostics = validate(root)
    if let first = diagnostics.first { throw first }
    return try serialize(root, styles: styleResolver)
  }

  private static func serialize(
    _ node: RenderNode,
    styles: (@Sendable ([StyleDeclaration]) -> String?)?
  ) throws -> String {
    switch node.renderingStorage {
    case .text(let text): escape(text)
    case .fragment(let children):
      try children.map { try serialize($0, styles: styles) }.joined()
    case .element(let element): try serialize(element, styles: styles)
    }
  }

  private static func serialize(
    _ element: RenderElement,
    styles: (@Sendable ([StyleDeclaration]) -> String?)?
  ) throws -> String {
    var attributes: [(name: String, value: String?)] = element.attributes.map {
      ($0.name, $0.value)
    }
    if !element.styles.isEmpty {
      guard let className = styles?(element.styles) else {
        throw RenderDiagnostic.unresolvedStyleDeclarations(element: element.kind)
      }
      attributes.append(("class", className))
    }
    let serializedAttributes = attributes.sorted {
      ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "")
    }.map { attribute in
      attribute.value.map { " \(attribute.name)=\"\(escape($0))\"" } ?? " \(attribute.name)"
    }.joined()

    if element.kind.isVoid { return "<\(element.kind.rawValue)\(serializedAttributes)>" }
    let children = try element.children.map { try serialize($0, styles: styles) }.joined()
    return "<\(element.kind.rawValue)\(serializedAttributes)>\(children)</\(element.kind.rawValue)>"
  }
}

extension RenderElement.Attribute {
  fileprivate var name: String {
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
    }
  }

  /// The serialized attribute value, or `nil` for a bare boolean attribute.
  fileprivate var value: String? {
    switch self {
    case .identifier(let value), .name(let value), .value(let value),
      .accessibilityLabel(let value), .href(let value), .source(let value),
      .sizes(let value),
      .alternateText(let value), .action(let value), .labelFor(let value),
      .title(let value), .sandbox(let value):
      value
    case .sourceSet(let candidates):
      candidates.sorted { ($0.width, $0.source) < ($1.width, $1.source) }
        .map { "\($0.source) \($0.width)w" }.joined(separator: ", ")
    case .syntaxLanguage(let value): value
    case .syntaxTheme(let value): value.rawValue
    case .syntaxHighlight(let value): value.rawValue
    case .buttonType(let value): value.rawValue
    case .inputType(let value): value.rawValue
    case .formMethod(let value): value.rawValue
    case .open: nil
    }
  }
}

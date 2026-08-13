import Foundation

public enum ElementName: String, Sendable {
  case article, button, code, div, footer, form, h1, h2, header, iframe, input, li
  case main, nav, p, pre, section, span, table, tbody, td, th, thead, tr, ul
}

public struct RenderAttribute: Equatable, Sendable {
  public let name: String
  public let value: String

  public init(_ name: String, _ value: String) {
    self.name = name
    self.value = value
  }
}

public struct ElementNode: Equatable, Sendable {
  public let name: ElementName
  public let attributes: [RenderAttribute]
  public let children: [RenderNode]

  public init(
    _ name: ElementName,
    attributes: [RenderAttribute] = [],
    @RenderBuilder children: () -> [RenderNode] = { [] }
  ) {
    self.name = name
    self.attributes = attributes
    self.children = children()
  }
}

public struct EmbedNode: Equatable, Sendable {
  public let source: String
  public let title: String

  public init(source: String, title: String) {
    self.source = source
    self.title = title
  }
}

public indirect enum RenderNode: Equatable, Sendable {
  case element(ElementNode)
  case text(String)
  case fragment([RenderNode])
  case embed(EmbedNode)
}

@resultBuilder
public enum RenderBuilder {
  public static func buildExpression(_ expression: RenderNode) -> [RenderNode] { [expression] }
  public static func buildExpression(_ expression: ElementNode) -> [RenderNode] {
    [.element(expression)]
  }
  public static func buildExpression(_ expression: String) -> [RenderNode] { [.text(expression)] }
  public static func buildBlock(_ components: [RenderNode]...) -> [RenderNode] {
    components.flatMap(\.self)
  }
  public static func buildOptional(_ component: [RenderNode]?) -> [RenderNode] { component ?? [] }
  public static func buildEither(first component: [RenderNode]) -> [RenderNode] { component }
  public static func buildEither(second component: [RenderNode]) -> [RenderNode] { component }
  public static func buildArray(_ components: [[RenderNode]]) -> [RenderNode] {
    components.flatMap(\.self)
  }
}

public protocol ValidationComponent: Sendable {
  @RenderBuilder var body: [RenderNode] { get }
}

extension ValidationComponent {
  public func resolve() -> RenderNode { .fragment(body) }
}

public enum RenderDiagnostic: Equatable, Error, Sendable {
  case duplicateAttribute(element: ElementName, name: String)
  case interactiveElementNestedInButton
  case invalidEmbedOrigin(String)
}

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

public enum HTMLRenderer {
  public static func render(_ node: RenderNode) -> String {
    switch node {
    case .text(let text):
      return escape(text)
    case .fragment(let children):
      return children.map(render).joined()
    case .embed(let embed):
      return
        #"<iframe sandbox="" src="\#(escape(embed.source))" title="\#(escape(embed.title))"></iframe>"#
    case .element(let element):
      let attributes = element.attributes.sorted {
        ($0.name, $0.value) < ($1.name, $1.value)
      }.map { #" \#($0.name)="\#(escape($0.value))""# }.joined()
      let children = element.children.map(render).joined()
      return "<\(element.name.rawValue)\(attributes)>\(children)</\(element.name.rawValue)>"
    }
  }

  public static func escape(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }
}

public struct RepresentativePage: ValidationComponent {
  public let includeFooter: Bool

  public init(includeFooter: Bool = true) {
    self.includeFooter = includeFooter
  }

  public var body: [RenderNode] {
    ElementNode(.main, attributes: [RenderAttribute("id", "content")]) {
      ElementNode(.header) { ElementNode(.h1) { "Robin validation" } }
      for section in 1...12 {
        ElementNode(.section, attributes: [RenderAttribute("data-section", "\(section)")]) {
          ElementNode(.h2) { "Section \(section)" }
          for item in 1...4 {
            ElementNode(.article) {
              ElementNode(.p) { "Item \(item) <is escaped>" }
            }
          }
        }
      }
      if includeFooter {
        ElementNode(.footer) { "Measured prototype" }
      }
    }
  }
}

import Foundation
@_spi(Rendering) import RobinHTML

/// A typed block-level node parsed from a content document.
public enum ContentNode: Equatable, Sendable {
  /// A section heading with its outline level (1–6).
  case heading(level: Int, id: String, content: [ContentInline])

  /// A paragraph of body text.
  case paragraph([ContentInline])

  /// A quoted block of phrasing content.
  case blockquote([ContentInline])

  /// An ordered or unordered list.
  case list(ordered: Bool, items: [[ContentInline]])

  /// A fenced code block with an optional language tag.
  case code(language: String?, source: String, highlights: [SyntaxHighlighter.Run])

  /// A table: the first row is the header, the rest are body rows.
  case table([[String]])

  /// A footnote definition, referenced by `id` from body text.
  case footnote(id: String, text: String, referenceCount: Int)

  /// A highlighted callout (note, tip, warning, or important).
  case admonition(AdmonitionNode)

  /// A typed external embed.
  case embed(source: String, title: String)
}

extension ParsedContent: Component {
  /// Native render content produced from the parsed Markdown tree.
  public var body: ComponentContent {
    ComponentContent(nodes: nodes.flatMap { $0.body.nodes })
  }
}

extension ContentNode {
  fileprivate var body: ComponentContent {
    switch self {
    case .heading(let level, let id, let content):
      return RobinHTML.Heading(headingLevel(level), id: id) { inlineContent(content) }.body
    case .paragraph(let content):
      return RobinHTML.Text { inlineContent(content) }.body
    case .blockquote(let content):
      return RobinHTML.Blockquote { RobinHTML.Text { inlineContent(content) } }.body
    case .list(let ordered, let items):
      return RobinHTML.List(ordered: ordered) {
        for item in items {
          RobinHTML.ListItem { inlineContent(item) }
        }
      }.body
    case .code(let language, _, let highlights):
      return RobinHTML.CodeBlock(highlights, language: language).body
    case .table(let rows):
      return RobinHTML.Table {
        for (rowIndex, row) in rows.enumerated() {
          RobinHTML.TableRow {
            for cell in row {
              if rowIndex == 0 {
                RobinHTML.TableHeaderCell { cell }
              } else {
                RobinHTML.TableCell { cell }
              }
            }
          }
        }
      }.body
    case .footnote(let id, let text, let referenceCount):
      return Aside(id: "fn-\(id)") {
        RobinHTML.Text {
          text
          if referenceCount > 0 {
            for occurrence in 1...referenceCount {
              RobinHTML.Link("#fnref-\(id)-\(occurrence)") { "↩" }
            }
          }
        }
      }.body
    case .admonition(let node):
      return Aside {
        RobinHTML.Heading(.three) { node.title }
        RobinHTML.Text { node.body }
      }.body
    case .embed(let source, let title):
      guard let url = URL(string: source), let host = url.host,
        let embed = try? Embed(source: url, title: title, allowedOrigins: ["https://\(host)"])
      else { return RobinHTML.Text { title }.body }
      return embed.body
    }
  }

  fileprivate func headingLevel(_ level: Int) -> RobinHTML.Heading.Level {
    switch level {
    case 1: .one
    case 2: .two
    case 3: .three
    case 4: .four
    case 5: .five
    default: .six
    }
  }
}

private func inlineContent(_ content: [ContentInline]) -> ComponentContent {
  ComponentContent(
    nodes: content.flatMap { inline -> [RenderNode] in
      switch inline {
      case .text(let text): return [.text(text)]
      case .emphasis(let children):
        return RobinHTML.Emphasis { inlineContent(children) }.body.nodes
      case .strong(let children):
        return RobinHTML.Strong { inlineContent(children) }.body.nodes
      case .code(let code): return RobinHTML.InlineCode { code }.body.nodes
      case .link(let destination, let children):
        let content = inlineContent(children)
        return ContentReferenceValidator.isSafeLinkDestination(destination)
          ? RobinHTML.Link(destination) { content }.body.nodes : content.nodes
      case .image(let source, let alternativeText):
        return RobinHTML.Image(source: source, alternateText: alternativeText).body.nodes
      case .footnoteReference(let id, let occurrence):
        return [
          .element(
            RenderElement(
              kind: .sup,
              children: RobinHTML.Link("#fn-\(id)", id: "fnref-\(id)-\(occurrence)") {
                "[\(id)]"
              }.body.nodes))
        ]
      }
    })
}

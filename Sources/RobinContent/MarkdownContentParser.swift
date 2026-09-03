import Foundation
import Markdown

/// Converts Markdown into Robin's typed content representation.
public struct MarkdownContentParser {
  /// Parses Markdown while rejecting raw HTML and embeds from hosts outside the allowlist.
  ///
  /// - Parameters:
  ///   - source: The Markdown source to parse.
  ///   - allowedEmbedHosts: Hostnames permitted in typed embed directives.
  /// - Returns: Parsed nodes and any nonfatal diagnostics.
  public static func parse(_ source: String, allowedEmbedHosts: Set<String>) -> ParsedContent {
    let document = Document(parsing: source, options: .parseBlockDirectives)
    var nodes: [ContentNode] = []
    var diagnostics: [ContentDiagnostic] = []

    for child in document.children {
      switch child {
      case let heading as Heading:
        nodes.append(.heading(level: heading.level, text: heading.plainText))
      case let paragraph as Paragraph:
        if paragraph.children.contains(where: { $0 is InlineHTML }) {
          diagnostics.append(.rawHTMLRejected)
        } else {
          nodes.append(.paragraph(paragraph.plainText))
        }
      case let code as CodeBlock:
        nodes.append(.code(language: code.language, source: code.code))
      case let table as Table:
        let head = [Array(table.head.cells.map(\.plainText))]
        let body = table.body.rows.map { Array($0.cells.map(\.plainText)) }
        nodes.append(.table(head + body))
      case is HTMLBlock:
        diagnostics.append(.rawHTMLRejected)
      case let directive as BlockDirective where directive.name == "Footnote":
        let arguments = arguments(of: directive)
        nodes.append(.footnote(id: arguments["id"] ?? "", text: plainText(directive)))
      case let directive as BlockDirective where directive.name == "Admonition":
        let arguments = arguments(of: directive)
        let kind = AdmonitionKind(rawValue: (arguments["kind"] ?? "note").lowercased())
        guard let kind else {
          diagnostics.append(.unsupportedNode("Admonition kind '\(arguments["kind"] ?? "")'"))
          continue
        }
        nodes.append(
          .admonition(
            AdmonitionNode(
              kind: kind,
              title: arguments["title"] ?? kind.rawValue.capitalized,
              body: plainText(directive))))
      case let directive as BlockDirective where directive.name == "Embed":
        let arguments = arguments(of: directive)
        let source = arguments["source"] ?? ""
        let host = URL(string: source)?.host
        if source.hasPrefix("https://"), let host, allowedEmbedHosts.contains(host) {
          nodes.append(.embed(source: source, title: arguments["title"] ?? "Embedded content"))
        } else {
          diagnostics.append(.invalidEmbed(source))
        }
      default:
        diagnostics.append(.unsupportedNode(String(describing: type(of: child))))
      }
    }
    return ParsedContent(nodes: nodes, diagnostics: diagnostics)
  }

  private static func plainText(_ markup: Markup) -> String {
    markup.children.compactMap { child in
      if let inline = child as? InlineMarkup { return inline.plainText }
      return plainText(child)
    }.joined(separator: " ")
  }

  private static func arguments(of directive: BlockDirective) -> [String: String] {
    Dictionary(
      uniqueKeysWithValues: directive.argumentText.parseNameValueArguments().map {
        ($0.name, $0.value)
      }
    )
  }
}

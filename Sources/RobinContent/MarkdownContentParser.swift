import Foundation
import Markdown
import RobinHTML

/// Converts Markdown into Robin's typed content representation.
public struct MarkdownContentParser {
  /// Parses Markdown while rejecting raw HTML and embeds from hosts outside the allowlist.
  ///
  /// - Parameters:
  ///   - source: The Markdown source to parse.
  ///   - allowedEmbedHosts: Hostnames permitted in typed embed directives.
  /// - Returns: Parsed nodes and any nonfatal diagnostics.
  public static func parse(_ source: String, allowedEmbedHosts: Set<String>) -> ParsedContent {
    let (frontMatter, body, frontMatterDiagnostics) = ContentFrontMatter.parse(source)
    let extracted = extractFootnotes(from: body)
    let document = Document(parsing: extracted.body, options: .parseBlockDirectives)
    var nodes: [ContentNode] = []
    var diagnostics = frontMatterDiagnostics + extracted.diagnostics
    var references: [ContentReference] = []
    var headingIDs: Set<String> = []
    var footnotes = extracted.definitions
    var footnoteOrder = extracted.order
    var footnoteReferences: [String: Int] = [:]
    collectReferences(in: document, into: &references)

    for child in document.children {
      switch child {
      case let heading as Markdown.Heading:
        let content = inlineNodes(heading, footnoteReferences: &footnoteReferences)
        nodes.append(
          .heading(
            level: heading.level,
            id: uniqueHeadingID(for: content.plainText, used: &headingIDs),
            content: content))
      case let paragraph as Paragraph:
        if paragraph.children.contains(where: { $0 is InlineHTML }) {
          diagnostics.append(.rawHTMLRejected)
        } else {
          nodes.append(.paragraph(inlineNodes(paragraph, footnoteReferences: &footnoteReferences)))
        }
      case let quote as BlockQuote:
        nodes.append(.blockquote(inlineNodes(quote, footnoteReferences: &footnoteReferences)))
      case let list as UnorderedList:
        nodes.append(
          .list(
            ordered: false,
            items: list.listItems.map {
              inlineNodes($0, footnoteReferences: &footnoteReferences)
            }))
      case let list as OrderedList:
        nodes.append(
          .list(
            ordered: true,
            items: list.listItems.map {
              inlineNodes($0, footnoteReferences: &footnoteReferences)
            }))
      case let code as Markdown.CodeBlock:
        nodes.append(
          .code(
            language: code.language,
            source: code.code,
            highlights: SyntaxHighlighter.highlight(code.code, language: code.language)))
      case let table as Markdown.Table:
        let head = [Array(table.head.cells.map(\.plainText))]
        let body = table.body.rows.map { Array($0.cells.map(\.plainText)) }
        nodes.append(.table(head + body))
      case is HTMLBlock:
        diagnostics.append(.rawHTMLRejected)
      case let directive as BlockDirective where directive.name == "Footnote":
        let arguments = arguments(of: directive)
        let id = arguments["id"] ?? ""
        if footnotes.updateValue(plainText(directive), forKey: id) == nil {
          footnoteOrder.append(id)
        } else {
          diagnostics.append(.duplicateFootnote(id))
        }
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
    for id in footnoteReferences.keys.sorted() where footnotes[id] == nil {
      diagnostics.append(.missingFootnote(id))
    }
    nodes += footnoteOrder.compactMap { id in
      guard let text = footnotes[id] else { return nil }
      return .footnote(id: id, text: text, referenceCount: footnoteReferences[id, default: 0])
    }
    return ParsedContent(
      frontMatter: frontMatter, nodes: nodes, references: references, diagnostics: diagnostics)
  }

  private static func collectReferences(
    in markup: Markup, into references: inout [ContentReference]
  ) {
    if let link = markup as? Markdown.Link, let destination = link.destination {
      references.append(.link(destination))
    } else if let image = markup as? Markdown.Image, let source = image.source {
      references.append(.asset(source))
    }
    for child in markup.children {
      collectReferences(in: child, into: &references)
    }
  }

  private static func inlineNodes(
    _ markup: Markup,
    footnoteReferences: inout [String: Int]
  ) -> [ContentInline] {
    markup.children.flatMap { child -> [ContentInline] in
      switch child {
      case let text as Markdown.Text:
        inlineText(text.string, footnoteReferences: &footnoteReferences)
      case let emphasis as Markdown.Emphasis:
        [.emphasis(inlineNodes(emphasis, footnoteReferences: &footnoteReferences))]
      case let strong as Markdown.Strong:
        [.strong(inlineNodes(strong, footnoteReferences: &footnoteReferences))]
      case let code as Markdown.InlineCode: [.code(code.code)]
      case let link as Markdown.Link:
        [
          .link(
            destination: link.destination ?? "",
            content: inlineNodes(link, footnoteReferences: &footnoteReferences))
        ]
      case let image as Markdown.Image:
        [.image(source: image.source ?? "", alternativeText: image.plainText)]
      case is SoftBreak, is LineBreak: [.text("\n")]
      default: inlineNodes(child, footnoteReferences: &footnoteReferences)
      }
    }
  }

  private static func inlineText(
    _ text: String,
    footnoteReferences: inout [String: Int]
  ) -> [ContentInline] {
    var result: [ContentInline] = []
    var remainder = text[...]
    while let start = remainder.range(of: "[^"),
      let end = remainder[start.upperBound...].firstIndex(of: "]")
    {
      if start.lowerBound > remainder.startIndex {
        result.append(.text(String(remainder[..<start.lowerBound])))
      }
      let id = String(remainder[start.upperBound..<end])
      guard isFootnoteID(id) else {
        result.append(.text(String(remainder[...end])))
        remainder = remainder[remainder.index(after: end)...]
        continue
      }
      footnoteReferences[id, default: 0] += 1
      result.append(.footnoteReference(id: id, occurrence: footnoteReferences[id, default: 0]))
      remainder = remainder[remainder.index(after: end)...]
    }
    if !remainder.isEmpty { result.append(.text(String(remainder))) }
    return result
  }

  private static func extractFootnotes(from source: String) -> (
    body: String,
    definitions: [String: String],
    order: [String],
    diagnostics: [ContentDiagnostic]
  ) {
    var definitions: [String: String] = [:]
    var order: [String] = []
    var diagnostics: [ContentDiagnostic] = []
    let body = source.split(separator: "\n", omittingEmptySubsequences: false).compactMap {
      line -> String? in
      let line = String(line)
      guard line.hasPrefix("[^"), let closing = line.firstIndex(of: "]"),
        line.index(after: closing) < line.endIndex,
        line[line.index(after: closing)] == ":"
      else { return line }
      let id = String(line[line.index(line.startIndex, offsetBy: 2)..<closing])
      guard isFootnoteID(id) else { return line }
      let text = line[line.index(closing, offsetBy: 2)...].trimmingCharacters(in: .whitespaces)
      if definitions.updateValue(text, forKey: id) == nil {
        order.append(id)
      } else {
        diagnostics.append(.duplicateFootnote(id))
      }
      return nil
    }.joined(separator: "\n")
    return (body, definitions, order, diagnostics)
  }

  private static func isFootnoteID(_ id: String) -> Bool {
    !id.isEmpty && id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
  }

  private static func uniqueHeadingID(for title: String, used: inout Set<String>) -> String {
    let base = title.lowercased().unicodeScalars.reduce(into: "") { result, scalar in
      if CharacterSet.alphanumerics.contains(scalar) {
        result.unicodeScalars.append(scalar)
      } else if !result.hasSuffix("-") {
        result.append("-")
      }
    }.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    let baseID = base.isEmpty ? "section" : base
    var id = baseID
    var suffix = 2
    while !used.insert(id).inserted {
      id = "\(baseID)-\(suffix)"
      suffix += 1
    }
    return id
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

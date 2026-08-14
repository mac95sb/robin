import Foundation
import RobinRendering
import Testing

@testable import RobinContent

@Suite("Markdown content parsing and embed/host validation")
struct MarkdownContentParserTests {
  @Test func realMarkdownBecomesTypedNodesAndRejectsRawHTML() throws {
    let url = try #require(
      Bundle.module.url(forResource: "long-form", withExtension: "md", subdirectory: "Fixtures")
    )
    let source = try String(contentsOf: url, encoding: .utf8)
    let parsed = MarkdownContentParser.parse(
      source, allowedEmbedHosts: ["www.youtube-nocookie.com"])

    #expect(parsed.nodes.contains { if case .code = $0 { true } else { false } })
    #expect(parsed.nodes.contains { if case .table = $0 { true } else { false } })
    #expect(parsed.nodes.contains { if case .footnote = $0 { true } else { false } })
    #expect(
      parsed.nodes.contains(
        .embed(
          EmbedNode(
            source: "https://www.youtube-nocookie.com/embed/example",
            title: "Validation video"
          )
        )
      )
    )
    #expect(parsed.diagnostics == [.rawHTMLRejected])
  }

  @Test func embedHostMustBeExplicitlyAllowed() {
    let parsed = MarkdownContentParser.parse(
      #"@Embed(source: "https://example.com/video", title: "Video")"#,
      allowedEmbedHosts: []
    )

    #expect(parsed.nodes.isEmpty)
    #expect(parsed.diagnostics == [.invalidEmbed("https://example.com/video")])
  }

  @Test func admonitionDirectiveBecomesTypedCalloutNode() {
    let parsed = MarkdownContentParser.parse(
      """
      @Admonition(kind: "warning", title: "Careful") {
        Rotating the key invalidates active sessions.
      }
      """,
      allowedEmbedHosts: []
    )

    #expect(
      parsed.nodes == [
        .admonition(
          AdmonitionNode(
            kind: .warning,
            title: "Careful",
            body: "Rotating the key invalidates active sessions."
          ))
      ]
    )
    #expect(parsed.diagnostics.isEmpty)
  }

  @Test func admonitionDefaultsToNoteKind() {
    let parsed = MarkdownContentParser.parse(
      """
      @Admonition {
        Footnotes render with back-references.
      }
      """,
      allowedEmbedHosts: []
    )

    #expect(
      parsed.nodes == [
        .admonition(
          AdmonitionNode(kind: .note, title: "Note", body: "Footnotes render with back-references.")
        )
      ]
    )
    #expect(parsed.diagnostics.isEmpty)
  }

  @Test func unknownAdmonitionKindIsReported() {
    let parsed = MarkdownContentParser.parse(
      """
      @Admonition(kind: "danger") {
        Not a supported kind.
      }
      """,
      allowedEmbedHosts: []
    )

    #expect(parsed.nodes.isEmpty)
    #expect(parsed.diagnostics == [.unsupportedNode("Admonition kind 'danger'")])
  }

  @Test func footnoteDirectiveBecomesTypedFootnoteNode() {
    let parsed = MarkdownContentParser.parse(
      """
      @Footnote(id: "fn1") {
        Block directives are case-sensitive.
      }
      """,
      allowedEmbedHosts: []
    )

    #expect(parsed.nodes == [.footnote(id: "fn1", text: "Block directives are case-sensitive.")])
    #expect(parsed.diagnostics.isEmpty)
  }
}

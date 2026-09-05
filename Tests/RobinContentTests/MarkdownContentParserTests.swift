import Foundation
import RobinHTML
import Testing

@testable import RobinContent

@Suite("Markdown content parsing and embed/host validation")
struct MarkdownContentParserTests {
  @Test func duplicateDirectiveArgumentsProduceDiagnostics() {
    for directive in [
      "@Footnote(id: a, id: b)", "@Admonition(kind: note, kind: warning)",
      "@Embed(source: \"https://example.com\", source: \"https://other.example\")",
    ] {
      let parsed = MarkdownContentParser.parse(directive, allowedEmbedHosts: ["example.com"])
      #expect(parsed.nodes.isEmpty)
      #expect(!parsed.diagnostics.isEmpty)
    }
  }

  @Test func paginationHandlesExtremePositiveInputs() throws {
    let parsed = MarkdownContentParser.parse("# Page", allowedEmbedHosts: [])
    let collection = ContentCollection([
      ContentDocument(id: "page", frontMatter: parsed.frontMatter, content: parsed)
    ])
    #expect(throws: ContentCollectionError.invalidPage) { try collection.page(Int.max, size: 2) }
    #expect(try collection.page(1, size: Int.max).documents.count == 1)
    #expect(try ContentCollection([]).page(1, size: Int.max).documents.isEmpty)
  }
  @Test func parsesTypedFrontMatterCollectionsAndPagination() throws {
    let parsed = MarkdownContentParser.parse(
      """
      ---
      title: First
      date: 2026-09-04T10:00:00Z
      locale: en-GB
      tags: [swift, web]
      ---
      # Hello
      """, allowedEmbedHosts: [])
    let first = ContentDocument(id: "first", frontMatter: parsed.frontMatter, content: parsed)
    let draft = ContentDocument(
      id: "draft", frontMatter: .init(title: "Draft", draft: true),
      content: .init(nodes: [], diagnostics: []))
    let collection = ContentCollection([draft, first])

    #expect(parsed.frontMatter.title == "First")
    #expect(parsed.frontMatter.metadata.description == nil)
    #expect(parsed.frontMatter.metadata.language == "en-GB")
    #expect(parsed.frontMatter.tags == ["swift", "web"])
    #expect(collection.documents.map(\.id) == ["first"])
    let page = try collection.page(1, size: 1)
    #expect(page.documents.map(\.id) == ["first"])
    #expect(page.route(basePath: "/articles") == "/articles")
    #expect(page.previousNumber == nil && page.nextNumber == nil)
    #expect(throws: ContentCollectionError.invalidPage) { try collection.page(2, size: 1) }
  }

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
          source: "https://www.youtube-nocookie.com/embed/example",
          title: "Validation video"
        )
      )
    )
    #expect(parsed.diagnostics == [.rawHTMLRejected])
  }

  @Test func fencedCodeUsesTheSharedSyntaxHighlighter() {
    let parsed = MarkdownContentParser.parse(
      """
      ```swift
      let answer = 42
      ```
      """, allowedEmbedHosts: [])

    guard case .code(_, let source, let highlights) = parsed.nodes.first else {
      Issue.record("Expected a code node")
      return
    }
    #expect(highlights == SyntaxHighlighter.highlight(source, language: "swift"))
  }

  @Test func parsedInlineMarkupRendersAsTypedHTML() throws {
    let parsed = MarkdownContentParser.parse(
      "Read **Robin** at [the guide](/guide) with `Swift` and ![logo](/logo.svg).",
      allowedEmbedHosts: [])

    #expect(
      try HTMLRenderer.render(parsed)
        == "<p>Read <strong>Robin</strong> at <a href=\"/guide\">the guide</a> with <code>Swift</code> and <img alt=\"logo\" src=\"/logo.svg\">.</p>"
    )
  }

  @Test func headingsProduceUniqueAnchorsAndTableOfContents() throws {
    let parsed = MarkdownContentParser.parse(
      "# Hello, Robin!\n\n## Hello Robin", allowedEmbedHosts: [])

    #expect(parsed.tableOfContents.map(\.id) == ["hello-robin", "hello-robin-2"])
    #expect(
      try HTMLRenderer.render(parsed)
        == "<h1 id=\"hello-robin\">Hello, Robin!</h1><h2 id=\"hello-robin-2\">Hello Robin</h2>")
  }

  @Test func listsAndQuotesRemainNativeWithoutJavaScript() throws {
    let parsed = MarkdownContentParser.parse(
      "> Quoted **text**\n\n1. First\n2. Second", allowedEmbedHosts: [])

    #expect(
      try HTMLRenderer.render(parsed)
        == "<blockquote><p>Quoted <strong>text</strong></p></blockquote><ol><li>First</li><li>Second</li></ol>"
    )
  }

  @Test func executableLinkSchemesRenderAsInertText() throws {
    for destination in [
      "javascript:alert(1)",
      "JaVaScRiPt:alert(1)",
      "data:text/html,unsafe",
      "java\nscript:alert(1)",
    ] {
      let content = MarkdownContentParser.parse(
        "[Safe label](\(destination))", allowedEmbedHosts: [])
      let html = try HTMLRenderer.render(content)
      #expect(html.contains("Safe label"))
      #expect(!html.contains("href="))
    }

    let safe = try HTMLRenderer.render(
      MarkdownContentParser.parse(
        "[Local](/about) [Web](https://example.com)", allowedEmbedHosts: [])
    )
    #expect(safe.contains("href=\"/about\""))
    #expect(safe.contains("href=\"https://example.com\""))
  }

  @Test func extractsAndValidatesLocalReferences() {
    let parsed = MarkdownContentParser.parse(
      "See [guide](guide) and ![logo](/images/logo.svg).", allowedEmbedHosts: [])
    let diagnostics = ContentReferenceValidator(
      routes: ["/docs", "/docs/guide"], assets: ["/images/logo.svg"]
    ).validate(parsed.references, from: "/docs/")

    #expect(parsed.references == [.link("guide"), .asset("/images/logo.svg")])
    #expect(diagnostics.isEmpty)
  }

  @Test func reportsBrokenUnsafeAndMissingReferences() {
    let parsed = MarkdownContentParser.parse(
      "[missing](/missing) [unsafe](../secret) ![missing](/missing.png)",
      allowedEmbedHosts: [])
    let diagnostics = ContentReferenceValidator(routes: [], assets: []).validate(
      parsed.references, from: "/docs/")

    #expect(
      diagnostics == [
        .brokenLink("/missing"),
        .invalidReference("../secret"),
        .missingAsset("/missing.png"),
      ])
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

    #expect(
      parsed.nodes == [
        .footnote(id: "fn1", text: "Block directives are case-sensitive.", referenceCount: 0)
      ])
    #expect(parsed.diagnostics.isEmpty)
  }

  @Test func standardFootnotesRenderForwardAndBackNavigationWithoutJavaScript() throws {
    let parsed = MarkdownContentParser.parse(
      "A native footnote[^one] and another reference[^one].\n\n[^one]: Fully typed.",
      allowedEmbedHosts: [])

    #expect(parsed.diagnostics.isEmpty)
    #expect(
      try HTMLRenderer.render(parsed)
        == "<p>A native footnote<sup><a href=\"#fn-one\" id=\"fnref-one-1\">[one]</a></sup> and another reference<sup><a href=\"#fn-one\" id=\"fnref-one-2\">[one]</a></sup>.</p><aside id=\"fn-one\"><p>Fully typed.<a href=\"#fnref-one-1\">↩</a><a href=\"#fnref-one-2\">↩</a></p></aside>"
    )
  }
}

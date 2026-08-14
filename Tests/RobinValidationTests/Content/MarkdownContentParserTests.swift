import Foundation
import Testing

@testable import RobinValidation

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
}

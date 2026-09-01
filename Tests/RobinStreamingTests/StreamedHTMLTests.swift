@_spi(Rendering) import RobinHTML
import Testing

@testable import RobinStreaming

@Suite("Streamed HTML chunks")
struct StreamedHTMLTests {
  @Test func renderedHTMLIsDividedIntoBoundedChunks() throws {
    let chunks = try StreamedHTML.chunks(
      for: .element(.init(kind: .p, children: [.text("User a b")])),
      chunkSize: 4
    )

    #expect(chunks.count > 1)
    #expect(chunks.allSatisfy { $0.readableBytes <= 4 })
  }
}

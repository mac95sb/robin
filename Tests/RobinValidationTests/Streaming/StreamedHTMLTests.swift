import Testing

@testable import RobinValidation

@Suite("Streamed HTML chunks")
struct StreamedHTMLTests {
  @Test func renderedHTMLIsDividedIntoBoundedChunks() {
    let chunks = StreamedHTML.chunks(
      for: .element(ElementNode(.p) { "User a b" }),
      chunkSize: 4
    )

    #expect(chunks.count > 1)
    #expect(chunks.allSatisfy { $0.readableBytes <= 4 })
  }
}

import Testing

@testable import RobinCore

@Suite("Metadata merging")
struct MetadataTests {
  @Test func pageValuesOverlayApplicationDefaultsFieldByField() {
    let application = Metadata(
      title: "Robin",
      description: "Application description",
      canonicalURL: "https://example.com",
      language: "en",
      image: .init(url: "https://example.com/default.png", alternativeText: "Default")
    )
    let page = Metadata(
      title: "Documentation",
      canonicalURL: "https://example.com/docs"
    )

    let merged = application.merging(page: page)

    #expect(merged.title == "Documentation")
    #expect(merged.description == "Application description")
    #expect(merged.canonicalURL == "https://example.com/docs")
    #expect(merged.language == "en")
    #expect(merged.image == application.image)
  }
}

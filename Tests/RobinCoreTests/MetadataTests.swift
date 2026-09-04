import Testing

@testable import RobinCore

@Suite("Metadata merging")
struct MetadataTests {
  @Test func robotsCanOverrideOrOmitTheDefault() {
    #expect(Metadata.Robots(follow: false).content == "index,nofollow")
    #expect(Metadata.Robots.omitted.content == nil)
  }

  @Test func pageValuesOverlayApplicationDefaultsFieldByField() {
    let application = Metadata(
      title: "Robin",
      site: "Robin Framework",
      description: "Application description",
      canonicalURL: "https://example.com",
      language: "en",
      image: .init(url: "https://example.com/default.png", alternativeText: "Default"),
      openGraph: .init(title: "Application social", description: "Social description")
    )
    let page = Metadata(
      title: "Documentation",
      canonicalURL: "https://example.com/docs",
      openGraph: .init(title: "Page social"),
      openGraphType: .article,
      xCardType: .summary
    )

    let merged = application.merging(page: page)

    #expect(merged.title == "Documentation")
    #expect(merged.composedTitle == "Documentation | Robin Framework")
    #expect(merged.description == "Application description")
    #expect(merged.canonicalURL == "https://example.com/docs")
    #expect(merged.language == "en")
    #expect(merged.image == application.image)
    #expect(merged.openGraph?.title == "Page social")
    #expect(merged.openGraph?.description == "Social description")
    #expect(merged.openGraphType == .article)
    #expect(merged.xCardType == .summary)
  }
}

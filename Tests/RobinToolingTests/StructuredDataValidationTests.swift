import RobinCore
import Testing

@testable import RobinTooling

@Suite("Structured data validation")
struct StructuredDataValidationTests {
  private let application = Metadata(
    title: "Robin",
    description: "Application description",
    canonicalURL: "https://example.com",
    language: "en-GB",
    image: .init(url: "https://example.com/default.png", alternativeText: "Robin")
  )

  @Test func everyChannelUsesTheFullyMergedMetadata() {
    let metadata = application.merging(
      page: Metadata(title: "Documentation", canonicalURL: "https://example.com/docs")
    )
    let projections = MetadataProjection.Channel.allCases.map {
      MetadataProjection(channel: $0, metadata: metadata)
    }

    #expect(
      StructuredDataValidation.validate(
        metadata: metadata,
        projections: projections,
        renderedText: "Documentation explains components.",
        describedContent: ["components"]
      ).isEmpty
    )
  }

  @Test func conflictingOrAbsentStructuredDataIsDiagnosed() {
    let metadata = application
    var projections = MetadataProjection.Channel.allCases.map {
      MetadataProjection(channel: $0, metadata: metadata)
    }
    projections.removeAll { $0.channel == .feed }
    projections.removeAll { $0.channel == .jsonLD }
    projections.append(MetadataProjection(channel: .jsonLD, metadata: Metadata(title: "Other")))

    #expect(
      StructuredDataValidation.validate(
        metadata: metadata,
        projections: projections,
        renderedText: "Robin",
        describedContent: ["Missing product"]
      ) == [
        .missingProjection(.feed),
        .conflictingProjection(.jsonLD),
        .describedContentAbsent("Missing product"),
      ]
    )
  }

  @Test func jsonLDSnapshotIsDeterministic() throws {
    let first = try StructuredDataValidation.jsonLDSnapshot(metadata: application)
    let second = try StructuredDataValidation.jsonLDSnapshot(metadata: application)

    #expect(first == second)
    #expect(
      first
        == #"{"@context":"https://schema.org","@type":"WebPage","description":"Application description","image":{"caption":"Robin","url":"https://example.com/default.png"},"inLanguage":"en-GB","name":"Robin","url":"https://example.com"}"#
    )
  }
}

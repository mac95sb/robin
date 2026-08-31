import Foundation
import RobinCore

/// A supported projection of shared page metadata.
public struct MetadataProjection: Equatable, Sendable {
  public enum Channel: String, CaseIterable, Sendable {
    case feed
    case html
    case jsonLD
    case openGraph
    case xCard
  }

  public let channel: Channel
  public let title: String?
  public let description: String?
  public let canonicalURL: String?
  public let language: String?
  public let imageURL: String?

  public init(channel: Channel, metadata: Metadata) {
    self.channel = channel
    title = metadata.title
    description = metadata.description
    canonicalURL = metadata.canonicalURL
    language = metadata.language
    imageURL = metadata.image?.url
  }
}

/// Validates projections derived from one fully merged ``Metadata`` value.
public enum StructuredDataValidation {
  public enum Violation: Equatable, Sendable {
    case missingProjection(MetadataProjection.Channel)
    case conflictingProjection(MetadataProjection.Channel)
    case describedContentAbsent(String)
  }

  public static func validate(
    metadata: Metadata,
    projections: [MetadataProjection],
    renderedText: String,
    describedContent: [String] = []
  ) -> [Violation] {
    MetadataProjection.Channel.allCases.compactMap { channel in
      guard let projection = projections.first(where: { $0.channel == channel }) else {
        return .missingProjection(channel)
      }
      return projection == MetadataProjection(channel: channel, metadata: metadata)
        ? nil : .conflictingProjection(channel)
    }
      + describedContent.compactMap { content in
        renderedText.contains(content) ? nil : .describedContentAbsent(content)
      }
  }

  /// Produces deterministic JSON-LD for snapshot validation from the resolved metadata.
  public static func jsonLDSnapshot(metadata: Metadata) throws -> String {
    let value = JSONLD(
      name: metadata.title,
      description: metadata.description,
      url: metadata.canonicalURL,
      inLanguage: metadata.language,
      image: metadata.image.map { .init(url: $0.url, caption: $0.alternativeText) }
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return String(decoding: try encoder.encode(value), as: UTF8.self)
  }

  private struct JSONLD: Encodable {
    struct Image: Encodable {
      let url: String
      let caption: String
    }

    let context = "https://schema.org"
    let type = "WebPage"
    let name: String?
    let description: String?
    let url: String?
    let inLanguage: String?
    let image: Image?

    enum CodingKeys: String, CodingKey {
      case context = "@context"
      case type = "@type"
      case name, description, url, inLanguage, image
    }
  }
}

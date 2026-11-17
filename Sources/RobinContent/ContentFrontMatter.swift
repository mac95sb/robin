import Foundation
import RobinCore
import Yams

/// Typed metadata parsed from a Markdown document's front matter.
public struct ContentFrontMatter: Equatable, Sendable {
  /// Robin's standard metadata projection source.
  public let metadata: Metadata
  /// Page title.
  public var title: String? { metadata.title }
  /// Short page summary.
  public var summary: String? { metadata.description }
  /// Route slug.
  public let slug: String?
  /// Content locale identifier.
  public var locale: String? { metadata.language }
  /// Publication date.
  public var publishedAt: Date? { metadata.publishedAt }
  /// Last modification date.
  public var modifiedAt: Date? { metadata.modifiedAt }
  /// Whether builds should omit the document.
  public let draft: Bool
  /// Ordered content tags.
  public let tags: [String]

  /// Creates typed content metadata.
  public init(
    title: String? = nil,
    summary: String? = nil,
    slug: String? = nil,
    locale: String? = nil,
    publishedAt: Date? = nil,
    modifiedAt: Date? = nil,
    draft: Bool = false,
    tags: [String] = []
  ) {
    self.metadata = Metadata(
      title: title,
      description: summary,
      language: locale,
      publishedAt: publishedAt,
      modifiedAt: modifiedAt
    )
    self.slug = slug
    self.draft = draft
    self.tags = tags
  }

  /// Creates front matter around fully typed Robin metadata.
  public init(
    metadata: Metadata,
    slug: String? = nil,
    draft: Bool = false,
    tags: [String] = []
  ) {
    self.metadata = metadata
    self.slug = slug
    self.draft = draft
    self.tags = tags
  }
}

extension ContentFrontMatter {
  /// Decodes Robin's shared fields and an application's metadata from the same YAML document.
  ///
  /// The returned body is the Markdown source after the closing front matter delimiter.
  public static func decode<Additional: Decodable>(
    _ type: Additional.Type,
    from source: String,
    file: String? = nil
  ) throws -> Decoded<Additional> {
    let (yaml, body) = split(source)
    guard let yaml else {
      throw FrontMatterDecodingError(
        file: file, message: "Missing opening or closing --- delimiter.")
    }

    do {
      let parser = try Parser(yaml: yaml)
      let node = try parser.singleRoot() ?? Node([:])
      let decoder = YAMLDecoder()
      let values = try decoder.decode(SharedFields.self, from: node)
      let additional = try decoder.decode(type, from: node)
      let formatter = ISO8601DateFormatter()
      let publishedAt = try parseDate(values.date, field: "date", file: file, formatter: formatter)
      let modifiedAt = try parseDate(
        values.modified, field: "modified", file: file, formatter: formatter)
      return Decoded(
        frontMatter: ContentFrontMatter(
          title: values.title, summary: values.summary, slug: values.slug, locale: values.locale,
          publishedAt: publishedAt, modifiedAt: modifiedAt, draft: values.draft ?? false,
          tags: values.tags ?? []),
        additional: additional,
        body: body)
    } catch let error as FrontMatterDecodingError {
      throw error
    } catch {
      throw FrontMatterDecodingError(file: file, message: String(describing: error))
    }
  }

  package static func parse(_ source: String) -> (Self, String, [ContentDiagnostic]) {
    let (yaml, body) = split(source)
    guard let yaml else { return (.init(), source, []) }
    do {
      let parser = try Parser(yaml: yaml)
      let node = try parser.singleRoot() ?? Node([:])
      let values = try YAMLDecoder().decode(SharedFields.self, from: node)
      let formatter = ISO8601DateFormatter()
      return (
        Self(
          title: values.title, summary: values.summary, slug: values.slug, locale: values.locale,
          publishedAt: try parseDate(values.date, field: "date", file: nil, formatter: formatter),
          modifiedAt: try parseDate(
            values.modified, field: "modified", file: nil, formatter: formatter),
          draft: values.draft ?? false, tags: values.tags ?? []),
        body, []
      )
    } catch {
      return (.init(), body, [.invalidFrontMatter(String(describing: error))])
    }
  }

  private static func split(_ source: String) -> (String?, String) {
    let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
    guard lines.first?.trimmingCharacters(in: .whitespaces) == "---",
      let end = lines.dropFirst().firstIndex(where: {
        $0.trimmingCharacters(in: .whitespaces) == "---"
      })
    else { return (nil, source) }
    return (
      lines[1..<end].joined(separator: "\n"),
      lines[lines.index(after: end)...].joined(separator: "\n")
    )
  }

  private static func parseDate(
    _ value: String?, field: String, file: String?, formatter: ISO8601DateFormatter
  ) throws -> Date? {
    guard let value else { return nil }
    guard let date = formatter.date(from: value) else {
      throw FrontMatterDecodingError(
        file: file, message: "Invalid ISO 8601 date in field '\(field)': \(value)")
    }
    return date
  }
}

/// A decoded front matter result with application metadata and the remaining Markdown body.
public struct DecodedFrontMatter<Additional: Decodable> {
  public let frontMatter: ContentFrontMatter
  public let additional: Additional
  public let body: String

  fileprivate init(frontMatter: ContentFrontMatter, additional: Additional, body: String) {
    self.frontMatter = frontMatter
    self.additional = additional
    self.body = body
  }
}

extension ContentFrontMatter {
  public typealias Decoded<Additional: Decodable> = DecodedFrontMatter<Additional>
}

private struct SharedFields: Decodable {
  let title: String?
  let summary: String?
  let slug: String?
  let locale: String?
  let date: String?
  let modified: String?
  let draft: Bool?
  let tags: [String]?
}

/// An error decoding document front matter.
public struct FrontMatterDecodingError: Error, LocalizedError {
  public let file: String?
  public let message: String

  public var errorDescription: String? {
    "\(file.map { "\($0): " } ?? "")front matter: \(message)"
  }

  fileprivate init(file: String?, message: String) {
    self.file = file
    self.message = message
  }
}

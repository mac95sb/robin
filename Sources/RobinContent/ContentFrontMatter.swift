import Foundation
import RobinCore

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
  package static func parse(_ source: String) -> (Self, String, [ContentDiagnostic]) {
    let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
    guard lines.first?.trimmingCharacters(in: .whitespaces) == "---",
      let end = lines.dropFirst().firstIndex(where: {
        $0.trimmingCharacters(in: .whitespaces) == "---"
      })
    else { return (.init(), source, []) }

    var values: [String: String] = [:]
    var diagnostics: [ContentDiagnostic] = []
    for line in lines[1..<end] {
      let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
      guard parts.count == 2 else {
        diagnostics.append(.invalidFrontMatter(String(line)))
        continue
      }
      values[parts[0].trimmingCharacters(in: .whitespaces)] =
        parts[1].trimmingCharacters(in: .whitespaces).unquoted
    }
    let formatter = ISO8601DateFormatter()
    let publishedAt = values["date"].flatMap(formatter.date)
    let modifiedAt = values["modified"].flatMap(formatter.date)
    if values["date"] != nil, publishedAt == nil { diagnostics.append(.invalidFrontMatter("date")) }
    if values["modified"] != nil, modifiedAt == nil {
      diagnostics.append(.invalidFrontMatter("modified"))
    }
    let tags =
      values["tags"].map {
        $0.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
          .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).unquoted }
      } ?? []
    let body = lines[lines.index(after: end)...].joined(separator: "\n")
    return (
      Self(
        title: values["title"], summary: values["summary"], slug: values["slug"],
        locale: values["locale"], publishedAt: publishedAt, modifiedAt: modifiedAt,
        draft: values["draft"]?.lowercased() == "true", tags: tags),
      body, diagnostics
    )
  }
}

extension String {
  fileprivate var unquoted: String {
    guard count >= 2, let first, let last, first == last, first == "\"" || first == "'" else {
      return self
    }
    return String(dropFirst().dropLast())
  }
}

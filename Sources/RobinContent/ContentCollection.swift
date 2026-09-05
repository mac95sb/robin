import Foundation

/// A deterministic collection of published content documents.
public struct ContentCollection: Sendable {
  /// Non-draft documents, newest first and then by stable identifier.
  public let documents: [ContentDocument]

  /// Creates a collection and omits drafts unless explicitly requested.
  public init(_ documents: [ContentDocument], includeDrafts: Bool = false) {
    self.documents = documents.filter { includeDrafts || !$0.frontMatter.draft }.sorted {
      let left = $0.frontMatter.publishedAt ?? .distantPast
      let right = $1.frontMatter.publishedAt ?? .distantPast
      return left == right ? $0.id < $1.id : left > right
    }
  }

  /// Returns one one-based page.
  public func page(_ number: Int, size: Int) throws -> ContentPage {
    guard number > 0, size > 0 else { throw ContentCollectionError.invalidPage }
    let totalPages = documents.isEmpty ? 1 : (documents.count - 1) / size + 1
    guard number <= totalPages else {
      throw ContentCollectionError.invalidPage
    }
    let start = (number - 1) * size
    return ContentPage(
      documents: Array(documents.dropFirst(start).prefix(size)), number: number,
      totalPages: totalPages)
  }

  /// Returns documents authored for one locale.
  public func localized(_ locale: String) -> ContentCollection {
    ContentCollection(documents.filter { $0.frontMatter.locale == locale }, includeDrafts: true)
  }
}

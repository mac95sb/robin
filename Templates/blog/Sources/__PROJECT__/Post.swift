import Foundation
import RobinContent

struct Post {
  static let english = load("first-post-en")
  static let french = load("first-post-fr")

  static var current: ParsedContent {
    t("postResource") == "first-post-fr" ? french : english
  }

  static var publicationDate: String {
    current.frontMatter.publishedAt.map { String($0.ISO8601Format().prefix(10)) } ?? ""
  }

  private static func load(_ name: String) -> ParsedContent {
    guard let url = Bundle.module.url(forResource: name, withExtension: "md"),
      let source = try? String(contentsOf: url, encoding: .utf8)
    else { preconditionFailure("Missing bundled Markdown post: \(name).md") }
    let post = MarkdownContentParser.parse(source, allowedEmbedHosts: [])
    precondition(post.diagnostics.isEmpty, "Invalid Markdown in \(name).md")
    return post
  }
}

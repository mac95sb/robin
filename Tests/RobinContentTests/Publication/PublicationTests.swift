import Foundation
import RobinContent
import RobinHTML
import Testing

@Suite("Native content publication")
struct PublicationTests {
  @Test func rendersEscapedRSSAtomAndLocalizedSitemap() {
    let date = Date(timeIntervalSince1970: 0)
    let feed = ContentFeed(
      title: "Robin & Swift", homeURL: "https://example.com",
      items: [
        FeedItem(
          title: "Typed <content>", url: "https://example.com/post", summary: "No JavaScript",
          publishedAt: date)
      ])
    let sitemap = Sitemap([
      SitemapEntry(
        url: "https://example.com/post", modifiedAt: date,
        alternates: ["fr": "https://example.com/fr/article"])
    ])

    #expect(feed.rss().contains("Robin &amp; Swift"))
    #expect(feed.rss().contains("<pubDate>Thu, 01 Jan 1970 00:00:00 +0000</pubDate>"))
    #expect(feed.atom().contains("<title>Typed &lt;content&gt;</title>"))
    #expect(sitemap.xml().contains("hreflang=\"fr\""))
    #expect(sitemap.xml().contains("<lastmod>1970-01-01</lastmod>"))
  }

  @Test func paginationRendersNativePreviousAndNextLinks() throws {
    let documents = (1...3).map {
      ContentDocument(
        id: String($0),
        frontMatter: .init(title: String($0)),
        content: .init(nodes: [], diagnostics: []))
    }
    let page = try ContentCollection(documents).page(2, size: 1)

    #expect(
      try HTMLRenderer.render(Pagination(page, basePath: "/articles"))
        == "<nav><a href=\"/articles\">Previous</a><p>Page 2 of 3</p><a href=\"/articles/page/3\">Next</a></nav>"
    )
  }
}

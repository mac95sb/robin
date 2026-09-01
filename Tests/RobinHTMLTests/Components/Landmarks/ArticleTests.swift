import RobinHTML
import Testing

@Suite("Article")
struct ArticleTests {
  @Test func articleLowersToArticleElement() throws {
    let article = try HTMLRenderer.render(Article(id: "post") { Text { "Body" } })

    #expect(article == #"<article id="post"><p>Body</p></article>"#)
  }
}

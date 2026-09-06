import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

struct PostPage: Page {
  let path = "/posts/a-quieter-web"

  var metadata: Metadata {
    var metadata = Post.current.frontMatter.metadata
    metadata.structuredData = [.article(.init(kind: .blogPosting))]
    return metadata
  }

  var body: ComponentContent {
    Stack {
      SiteHeader()
      Main {
        Article {
          Link(localizedPath("/")) { t("backToJournal") }.starterLink()
          Text { "\(Post.publicationDate) · \(t("postCategory"))" }.margin(.zero).starterLink()
          Heading { Post.current.frontMatter.title ?? "" }
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
          Text { Post.current.frontMatter.summary ?? "" }
            .margin(.zero).font(.body, color: .muted, lineHeight: 30)
            .font(.body, color: .muted, lineHeight: 30, on: .dark)
          Stack {}.starterRule()
          Post.current.margin(.zero)
        }.grid(columns: 1, gap: .lg).font(.body, lineHeight: 30)
          .frame(maxWidth: 800).flexItem(grow: 1)
      }.flex(justify: .center)
      SiteFooter()
    }.starterPage()
  }
}

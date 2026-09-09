import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

/// Renders the bundled Markdown post.
struct PostPage: Page {
  let path = "/posts/a-quieter-web"

  var metadata: Metadata {
    var metadata = Post.current.frontMatter.metadata
    metadata.structuredData = [.article(.init(kind: .blogPosting))]
    return metadata
  }

  var body: ComponentContent {
    BlogPage {
      SiteHeader()
      Main {
        Article {
          SiteLabel { Link(localizedPath("/")) { t("backToJournal") } }
          SiteLabel { Text { "\(Post.publicationDate) · \(t("postCategory"))" }.margin(.zero) }
          Heading { Post.current.frontMatter.title ?? "" }
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
          Text { Post.current.frontMatter.summary ?? "" }
            .margin(.zero).font(.body, color: .muted, lineHeight: 30)
            .font(color: .muted, on: .dark)
          SiteRule()
          Post.current.margin(.zero)
        }
        .grid(columns: 1, gap: .lg).font(.body, lineHeight: 30)
        .frame(maxWidth: 800).flexItem(grow: 1)
      }
      .flex(justify: .center)
      SiteFooter()
    }
  }
}

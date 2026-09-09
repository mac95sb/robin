import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

/// Lists the blog’s featured Markdown post.
struct HomePage: Page {
  let path = "/"

  var metadata: Metadata {
    Metadata(title: t("home"), description: t("intro"), structuredData: [.blog])
  }

  var body: ComponentContent {
    BlogPage {
      SiteHeader()
      Main {
        Section {
          SiteLabel { Text { t("journalLabel") }.margin(.zero) }
          Heading { t("journalTitle") }
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
            .font(.heading, lineHeight: 70, letterSpacing: -2, on: .md)
          Text { t("journalIntro") }
            .margin(.zero).frame(maxWidth: 560)
            .font(.body, color: .muted, lineHeight: 28)
            .font(color: .muted, on: .dark)
        }
        .grid(columns: 1, gap: .lg).padding(.lg)

        SiteRule()

        Link(localizedPath("/posts/a-quieter-web")) {
          Stack {
            Stack {
              SiteLabel { Text { t("featuredPost") }.margin(.zero) }
              SiteLabel { Text { Post.publicationDate }.margin(.zero) }
            }
            .flex(wrap: .wrap, justify: .spaceBetween, gap: .md)
            PageTitle { Heading(.two) { Post.current.frontMatter.title ?? "" } }
            Text { Post.current.frontMatter.summary ?? "" }
              .margin(.zero).frame(maxWidth: 640)
            SiteLabel { Text { t("readPost") } }
          }
          .grid(columns: 1, gap: .lg)
        }
        .padding(.lg)
        .border(color: .border, width: 0, radius: .xl)
        .font(.body, color: .foreground, decoration: TextDecoration.none)
        .font(color: .foreground, on: .dark)
        .background(color: .cardHover, on: .hover || .focus)
        .background(color: .cardHover, on: .dark && (.hover || .focus))
      }
      .grid(columns: 1, gap: .xxl)
      SiteFooter()
    }
  }
}

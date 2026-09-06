import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

struct HomePage: Page {
  let path = "/"

  var metadata: Metadata {
    Metadata(title: t("home"), description: t("intro"), structuredData: [.blog])
  }

  var body: ComponentContent {
    Stack {
      SiteHeader()
      Main {
        Section {
          Text { t("journalLabel") }.margin(.zero).starterLink()
          Heading { t("journalTitle") }
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
            .font(.heading, lineHeight: 70, letterSpacing: -2, on: .md)
          Text { t("journalIntro") }
            .margin(.zero).frame(maxWidth: 560)
            .font(.body, color: .muted, lineHeight: 28)
            .font(.body, color: .muted, lineHeight: 28, on: .dark)
        }.grid(columns: 1, gap: .lg).padding(.lg)

        Stack {}.starterRule()

        Link(localizedPath("/posts/a-quieter-web")) {
          Stack {
            Stack {
              Text { t("featuredPost") }.margin(.zero).starterLink()
              Text { Post.publicationDate }.margin(.zero).starterLink()
            }.flex(wrap: .wrap, justify: .spaceBetween, gap: .md)
            Heading(.two) { Post.current.frontMatter.title ?? "" }.starterTitle()
            Text { Post.current.frontMatter.summary ?? "" }
              .margin(.zero).frame(maxWidth: 640)
            Text { t("readPost") }.starterLink()
          }.grid(columns: 1, gap: .lg)
        }
        .padding(.lg)
        .border(color: .border, width: 0, radius: .xl)
        .font(.body, color: .foreground, decoration: TextDecoration.none)
        .font(.body, color: .foreground, on: .dark)
        .background(color: .cardHover, on: .hover || .focus)
        .background(color: .cardHover, on: .dark && (.hover || .focus))
      }.grid(columns: 1, gap: .xxl)
      SiteFooter()
    }.starterPage()
  }
}

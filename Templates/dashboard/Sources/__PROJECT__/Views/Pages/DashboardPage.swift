import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

struct DashboardPage: Page {
  let path = "/"
  var metadata: Metadata {
    Metadata(title: t("dashboard"), description: t("overviewIntro"))
  }

  var body: ComponentContent {
    Stack {
      SiteHeader()
      Main {
        Stack {
          Text { "WORKSPACE / OVERVIEW" }.margin(.zero).starterLink()
          Heading { t("title") }
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
            .font(.heading, lineHeight: 70, letterSpacing: -2, on: .md)
          Text { t("overviewIntro") }
            .margin(.zero).frame(maxWidth: 560)
            .font(.body, color: .muted, lineHeight: 28)
            .font(.body, color: .muted, lineHeight: 28, on: .dark)
          Stack {
            Text { t("serverRenderedPages") }.margin(.zero).starterLink()
            Text { t("typedRoutes") }.margin(.zero).starterLink()
            Text { t("sharedMetadata") }.margin(.zero).starterLink()
          }.flex(wrap: .wrap, gap: .lg)
        }.grid(columns: 1, gap: .lg).padding(.lg)

        Stack {
          Link(localizedPath("/notes")) {
            Heading(.two) { t("notes") }.starterTitle()
            Text { t("notesIntro") }.margin(.zero)
            Text { t("openNotes") }.margin(.zero).starterLink()
          }.grid(columns: 1, gap: .lg).starterPanel()
            .font(.body, color: .foreground, decoration: TextDecoration.none)
            .font(.body, color: .foreground, on: .dark)
          Link(localizedPath("/conversations")) {
            Heading(.two) { t("conversations") }.starterTitle()
            Text { t("conversationsOverview") }.margin(.zero)
            Text { t("openConversations") }.margin(.zero).starterLink()
          }.grid(columns: 1, gap: .lg).starterPanel()
            .font(.body, color: .foreground, decoration: TextDecoration.none)
            .font(.body, color: .foreground, on: .dark)
        }.grid(columns: 1, gap: .lg).grid(columns: 2, gap: .lg, on: .md)

      }.grid(columns: 1, gap: .xxl)
      SiteFooter()
    }.starterPage()
  }
}

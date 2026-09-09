import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

/// Introduces the workspace and links to its application pages.
struct DashboardPage: Page {
  let path = "/"
  var metadata: Metadata {
    Metadata(title: t("dashboard"), description: t("overviewIntro"))
  }

  var body: ComponentContent {
    DashboardPageLayout {
      SiteHeader()
      Main {
        Stack {
          DashboardLabel { Text { "WORKSPACE / OVERVIEW" }.margin(.zero) }
          Heading { t("title") }
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
            .font(.heading, lineHeight: 70, letterSpacing: -2, on: .md)
          Text { t("overviewIntro") }
            .margin(.zero).frame(maxWidth: 560)
            .font(.body, color: .muted, lineHeight: 28)
            .font(color: .muted, on: .dark)
          Stack {
            DashboardLabel { Text { t("serverRenderedPages") }.margin(.zero) }
            DashboardLabel { Text { t("typedRoutes") }.margin(.zero) }
            DashboardLabel { Text { t("sharedMetadata") }.margin(.zero) }
          }
          .flex(wrap: .wrap, gap: .lg)
        }
        .grid(columns: 1, gap: .lg).padding(.lg)

        Stack {
          DashboardPanel {
            Link(localizedPath("/notes")) {
              DashboardTitle { Heading(.two) { t("notes") } }
              Text { t("notesIntro") }.margin(.zero)
              DashboardLabel { Text { t("openNotes") }.margin(.zero) }
            }
            .grid(columns: 1, gap: .lg)
          }
          .font(.body, color: .foreground, decoration: TextDecoration.none)
          .font(color: .foreground, on: .dark)
          DashboardPanel {
            Link(localizedPath("/conversations")) {
              DashboardTitle { Heading(.two) { t("conversations") } }
              Text { t("conversationsOverview") }.margin(.zero)
              DashboardLabel { Text { t("openConversations") }.margin(.zero) }
            }
            .grid(columns: 1, gap: .lg)
          }
          .font(.body, color: .foreground, decoration: TextDecoration.none)
          .font(color: .foreground, on: .dark)
        }
        .grid(columns: 1, gap: .lg).grid(columns: 2, gap: .lg, on: .md)

      }
      .grid(columns: 1, gap: .xxl)
      SiteFooter()
    }
  }
}

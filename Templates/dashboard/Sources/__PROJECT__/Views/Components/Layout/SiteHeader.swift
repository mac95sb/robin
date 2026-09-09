import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

/// Renders the shared responsive workspace navigation.
struct SiteHeader: Component {
  var body: ComponentContent {
    Header {
      Stack {
        Link(localizedPath("/")) { "Workspace" }
          .font(.body, color: .foreground, decoration: TextDecoration.none)
          .font(
            color: .foreground,
            on: .dark
          )
        Navigation {
          DashboardLabel { Link(localizedPath("/notes")) { t("notes") } }
          DashboardLabel { Link(localizedPath("/conversations")) { t("conversations") } }
          Stack {
            Popover {
              DashboardPicker {
                Button(accessibilityLabel: "Language") {
                  Text { localizedPath("/") == "/fr" ? "FR" : "EN" }
                }
              }
            } content: {
              DashboardPopover {
                Stack {
                  DashboardMenuItem { LanguageLink(.init(code: "en", name: "EN")) { "EN" } }
                  DashboardMenuItem { LanguageLink(.init(code: "fr", name: "FR")) { "FR" } }
                }
                .grid(columns: 1, gap: .xs)
              }
            }
            .hidden(on: .below(.md))
            Popover {
              DashboardPicker {
                Button(accessibilityLabel: "Appearance") {
                  Icon(.sunMoon, size: 18)
                }
              }
            } content: {
              DashboardPopover {
                Stack {
                  DashboardMenuItem {
                    AppearanceButton(
                      .system,
                      preferences: Site.preferences.binding,
                      accessibilityLabel: localizedPath("/") == "/fr" ? "Système" : "System"
                    ) {
                      Icon(.monitor, size: 18)
                      Text { localizedPath("/") == "/fr" ? "Système" : "System" }
                    }
                  }
                  DashboardMenuItem {
                    AppearanceButton(
                      .light,
                      preferences: Site.preferences.binding,
                      accessibilityLabel: localizedPath("/") == "/fr" ? "Clair" : "Light"
                    ) {
                      Icon(.sun, size: 18)
                      Text { localizedPath("/") == "/fr" ? "Clair" : "Light" }
                    }
                  }
                  DashboardMenuItem {
                    AppearanceButton(
                      .dark,
                      preferences: Site.preferences.binding,
                      accessibilityLabel: localizedPath("/") == "/fr" ? "Sombre" : "Dark"
                    ) {
                      Icon(.moon, size: 18)
                      Text { localizedPath("/") == "/fr" ? "Sombre" : "Dark" }
                    }
                  }
                }
                .grid(columns: 1, gap: .xs)
              }
            }
            .hidden(on: .below(.md))
          }
          .flex(align: .center, gap: .sm)
        }
        .flex(wrap: .wrap, align: .center, gap: .lg)
        .hidden(on: .below(.md))
        MobileMenu()
      }
      .flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
      DashboardRule()
    }
    .grid(columns: 1, gap: .lg)
  }
}

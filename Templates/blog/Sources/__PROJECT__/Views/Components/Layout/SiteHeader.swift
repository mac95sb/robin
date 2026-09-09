import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

/// Renders the shared responsive blog navigation.
struct SiteHeader: Component {
  var body: ComponentContent {
    Header {
      Stack {
        Link(localizedPath("/")) { "Journal" }
          .font(.body, color: .foreground, decoration: TextDecoration.none)
          .font(
            color: .foreground,
            on: .dark
          )
        Navigation {
          SiteLabel { Link(localizedPath("/")) { "Journal" } }
          SiteLabel { Link(localizedPath("/about")) { t("about") } }
          Stack {
            Popover {
              MenuTrigger {
                Button(accessibilityLabel: "Language") {
                  Text { localizedPath("/") == "/fr" ? "FR" : "EN" }
                }
              }
            } content: {
              MenuPopover {
                Stack {
                  MenuItem { LanguageLink(.init(code: "en", name: "EN")) { "EN" } }
                  MenuItem { LanguageLink(.init(code: "fr", name: "FR")) { "FR" } }
                }
                .grid(columns: 1, gap: .xs)
              }
            }
            .hidden(on: .below(.md))
            Popover {
              MenuTrigger {
                Button(accessibilityLabel: "Appearance") {
                  Icon(.sunMoon, size: 18)
                }
              }
            } content: {
              MenuPopover {
                Stack {
                  MenuItem {
                    AppearanceButton(
                      .system,
                      preferences: Site.preferences.binding,
                      accessibilityLabel: localizedPath("/") == "/fr" ? "Système" : "System"
                    ) {
                      Icon(.monitor, size: 18)
                      Text { localizedPath("/") == "/fr" ? "Système" : "System" }
                    }
                  }
                  MenuItem {
                    AppearanceButton(
                      .light,
                      preferences: Site.preferences.binding,
                      accessibilityLabel: localizedPath("/") == "/fr" ? "Clair" : "Light"
                    ) {
                      Icon(.sun, size: 18)
                      Text { localizedPath("/") == "/fr" ? "Clair" : "Light" }
                    }
                  }
                  MenuItem {
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
      SiteRule()
    }
    .grid(columns: 1, gap: .lg)
  }
}

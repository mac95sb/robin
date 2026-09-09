import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

/// Provides the compact navigation menu for small screens.
struct MobileMenu: Component {
  var body: ComponentContent {
    Popover {
      MenuTrigger {
        Button(accessibilityLabel: "Menu") {
          Icon(.menu, size: 18)
        }
      }
    } content: {
      MenuPopover {
        Navigation {
          MenuItem { Link(localizedPath("/")) { "Journal" } }
          MenuItem { Link(localizedPath("/about")) { t("about") } }
          SiteRule()
          Stack {
            MenuItem { LanguageLink(.init(code: "en", name: "EN")) { "EN" } }
            MenuItem { LanguageLink(.init(code: "fr", name: "FR")) { "FR" } }
          }
          .flex(gap: .sm)
          SiteRule()
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
      .frame(width: 240)
    }
    .hidden(on: .md)
  }
}

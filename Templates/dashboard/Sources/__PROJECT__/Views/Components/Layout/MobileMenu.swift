import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

/// Provides the compact workspace navigation for small screens.
struct MobileMenu: Component {
  var body: ComponentContent {
    Popover {
      DashboardPicker {
        Button(accessibilityLabel: "Menu") {
          Icon(.menu, size: 18)
        }
      }
    } content: {
      DashboardPopover {
        Navigation {
          DashboardMenuItem { Link(localizedPath("/notes")) { t("notes") } }
          DashboardMenuItem { Link(localizedPath("/conversations")) { t("conversations") } }
          DashboardRule()
          Stack {
            DashboardMenuItem { LanguageLink(.init(code: "en", name: "EN")) { "EN" } }
            DashboardMenuItem { LanguageLink(.init(code: "fr", name: "FR")) { "FR" } }
          }
          .flex(gap: .sm)
          DashboardRule()
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
      .frame(width: 240)
    }
    .hidden(on: .md)
  }
}

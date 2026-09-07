import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

/// Provides the compact navigation menu for small screens.
struct MobileMenu: Component {
  private let menuAnchor = try! Anchor("mobile-menu")

  var body: ComponentContent {
    MenuTrigger {
      Button(accessibilityLabel: "Menu", command: .toggle("mobile-menu")) {
        Icon(.menu, size: 18)
      }
    }.anchor(menuAnchor).hidden(on: .md)
    MenuPopover {
      Popover(id: "mobile-menu") {
        Navigation {
          MenuItem { Link(localizedPath("/")) { "Journal" } }
          MenuItem { Link(localizedPath("/about")) { t("about") } }
          SiteRule()
          Stack {
            MenuItem { LanguageLink(.init(code: "en", name: "EN")) { "EN" } }
            MenuItem { LanguageLink(.init(code: "fr", name: "FR")) { "FR" } }
          }.flex(gap: .sm)
          SiteRule()
          MenuItem {
            AppearanceButton(
              .system, accessibilityLabel: localizedPath("/") == "/fr" ? "Système" : "System"
            ) {
              Icon(.monitor, size: 18)
              Text { localizedPath("/") == "/fr" ? "Système" : "System" }
            }
          }
          MenuItem {
            AppearanceButton(
              .light, accessibilityLabel: localizedPath("/") == "/fr" ? "Clair" : "Light"
            ) {
              Icon(.sun, size: 18)
              Text { localizedPath("/") == "/fr" ? "Clair" : "Light" }
            }
          }
          MenuItem {
            AppearanceButton(
              .dark, accessibilityLabel: localizedPath("/") == "/fr" ? "Sombre" : "Dark"
            ) {
              Icon(.moon, size: 18)
              Text { localizedPath("/") == "/fr" ? "Sombre" : "Dark" }
            }
          }
        }.grid(columns: 1, gap: .xs)
      }
    }.frame(width: 240).position(at: menuAnchor).hidden(on: .md)
  }
}

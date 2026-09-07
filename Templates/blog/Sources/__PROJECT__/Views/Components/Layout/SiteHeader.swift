import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

/// Renders the shared responsive blog navigation.
struct SiteHeader: Component {
  private let languageAnchor = try! Anchor("language-menu")
  private let appearanceAnchor = try! Anchor("appearance-menu")

  var body: ComponentContent {
    Header {
      Stack {
        Link(localizedPath("/")) { "Journal" }
          .font(.body, color: .foreground, decoration: TextDecoration.none).font(
            .body, color: .foreground, on: .dark)
        Navigation {
          SiteLabel { Link(localizedPath("/")) { "Journal" } }
          SiteLabel { Link(localizedPath("/about")) { t("about") } }
          Stack {
            MenuTrigger {
              Button(accessibilityLabel: "Language", command: .toggle("language-menu")) {
                Text { localizedPath("/") == "/fr" ? "FR" : "EN" }
              }
            }.anchor(languageAnchor)
            MenuPopover {
              Popover(id: "language-menu") {
                Stack {
                  MenuItem { LanguageLink(.init(code: "en", name: "EN")) { "EN" } }
                  MenuItem { LanguageLink(.init(code: "fr", name: "FR")) { "FR" } }
                }.grid(columns: 1, gap: .xs)
              }
            }.position(at: languageAnchor).hidden(on: .below(.md))
            MenuTrigger {
              Button(accessibilityLabel: "Appearance", command: .toggle("appearance-menu")) {
                Icon(.sunMoon, size: 18)
              }
            }.anchor(appearanceAnchor)
            MenuPopover {
              Popover(id: "appearance-menu") {
                Stack {
                  MenuItem {
                    AppearanceButton(
                      .system,
                      accessibilityLabel: localizedPath("/") == "/fr" ? "Système" : "System"
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
            }.position(at: appearanceAnchor).hidden(on: .below(.md))
          }.flex(align: .center, gap: .sm)
        }.flex(wrap: .wrap, align: .center, gap: .lg)
          .hidden(on: .below(.md))
        MobileMenu()
      }.flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
      SiteRule()
    }.grid(columns: 1, gap: .lg)
  }
}

import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

/// Renders the shared responsive workspace navigation.
struct SiteHeader: Component {
  private let languageAnchor = try! Anchor("language-menu")
  private let appearanceAnchor = try! Anchor("appearance-menu")

  var body: ComponentContent {
    Header {
      Stack {
        Link(localizedPath("/")) { "Workspace" }
          .font(.body, color: .foreground, decoration: TextDecoration.none).font(
            .body, color: .foreground, on: .dark)
        Navigation {
          DashboardLabel { Link(localizedPath("/notes")) { t("notes") } }
          DashboardLabel { Link(localizedPath("/conversations")) { t("conversations") } }
          Stack {
            DashboardPicker {
              Button(accessibilityLabel: "Language", command: .toggle("language-menu")) {
                Text { localizedPath("/") == "/fr" ? "FR" : "EN" }
              }
            }.anchor(languageAnchor)
            DashboardPopover {
              Popover(id: "language-menu") {
                Stack {
                  DashboardMenuItem { LanguageLink(.init(code: "en", name: "EN")) { "EN" } }
                  DashboardMenuItem { LanguageLink(.init(code: "fr", name: "FR")) { "FR" } }
                }.grid(columns: 1, gap: .xs)
              }
            }.position(at: languageAnchor).hidden(on: .below(.md))
            DashboardPicker {
              Button(accessibilityLabel: "Appearance", command: .toggle("appearance-menu")) {
                Icon(.sunMoon, size: 18)
              }
            }.anchor(appearanceAnchor)
            DashboardPopover {
              Popover(id: "appearance-menu") {
                Stack {
                  DashboardMenuItem {
                    AppearanceButton(
                      .system,
                      accessibilityLabel: localizedPath("/") == "/fr" ? "Système" : "System"
                    ) {
                      Icon(.monitor, size: 18)
                      Text { localizedPath("/") == "/fr" ? "Système" : "System" }
                    }
                  }
                  DashboardMenuItem {
                    AppearanceButton(
                      .light, accessibilityLabel: localizedPath("/") == "/fr" ? "Clair" : "Light"
                    ) {
                      Icon(.sun, size: 18)
                      Text { localizedPath("/") == "/fr" ? "Clair" : "Light" }
                    }
                  }
                  DashboardMenuItem {
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
      DashboardRule()
    }.grid(columns: 1, gap: .lg)
  }
}

import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

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
          Link(localizedPath("/")) { "Journal" }.starterLink()
          Link(localizedPath("/about")) { t("about") }.starterLink()
          Stack {
            Button(accessibilityLabel: "Language", command: .toggle("language-menu")) {
              Text { localizedPath("/") == "/fr" ? "FR" : "EN" }
            }.starterPicker().anchor(languageAnchor)
            Popover(id: "language-menu") {
              Stack {
                LanguageLink(.init(code: "en", name: "EN")) { "EN" }.starterMenuItem()
                LanguageLink(.init(code: "fr", name: "FR")) { "FR" }.starterMenuItem()
              }.grid(columns: 1, gap: .xs)
            }.starterPopover().position(at: languageAnchor).hidden(on: .below(.md))
            Button(accessibilityLabel: "Appearance", command: .toggle("appearance-menu")) {
              Icon(.sunMoon, size: 18)
            }.starterPicker().anchor(appearanceAnchor)
            Popover(id: "appearance-menu") {
              Stack {
                AppearanceButton(
                  .system, accessibilityLabel: localizedPath("/") == "/fr" ? "Système" : "System"
                ) {
                  Icon(.monitor, size: 18)
                  Text { localizedPath("/") == "/fr" ? "Système" : "System" }
                }.starterMenuItem()
                AppearanceButton(
                  .light, accessibilityLabel: localizedPath("/") == "/fr" ? "Clair" : "Light"
                ) {
                  Icon(.sun, size: 18)
                  Text { localizedPath("/") == "/fr" ? "Clair" : "Light" }
                }.starterMenuItem()
                AppearanceButton(
                  .dark, accessibilityLabel: localizedPath("/") == "/fr" ? "Sombre" : "Dark"
                ) {
                  Icon(.moon, size: 18)
                  Text { localizedPath("/") == "/fr" ? "Sombre" : "Dark" }
                }.starterMenuItem()
              }.grid(columns: 1, gap: .xs)
            }.starterPopover().position(at: appearanceAnchor).hidden(on: .below(.md))
          }.flex(align: .center, gap: .sm)
        }.flex(wrap: .wrap, align: .center, gap: .lg)
          .hidden(on: .below(.md))
        MobileMenu()
      }.flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
      Stack {}.starterRule()
    }.grid(columns: 1, gap: .lg)
  }
}

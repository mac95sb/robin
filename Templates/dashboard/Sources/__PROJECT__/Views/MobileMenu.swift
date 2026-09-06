import RobinContent
import RobinHTML
import RobinLucide
import RobinStyle

struct MobileMenu: Component {
  private let menuAnchor = try! Anchor("mobile-menu")

  var body: ComponentContent {
    Button(accessibilityLabel: "Menu", command: .toggle("mobile-menu")) {
      Icon(.menu, size: 18)
    }.starterPicker().anchor(menuAnchor).hidden(on: .md)
    Popover(id: "mobile-menu") {
      Navigation {
        Link(localizedPath("/notes")) { t("notes") }.starterMenuItem()
        Link(localizedPath("/conversations")) { t("conversations") }.starterMenuItem()
        Stack {}.starterRule()
        Stack {
          LanguageLink(.init(code: "en", name: "EN")) { "EN" }.starterMenuItem()
          LanguageLink(.init(code: "fr", name: "FR")) { "FR" }.starterMenuItem()
        }.flex(gap: .sm)
        Stack {}.starterRule()
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
    }.starterPopover().frame(width: 240).position(at: menuAnchor).hidden(on: .md)
  }
}

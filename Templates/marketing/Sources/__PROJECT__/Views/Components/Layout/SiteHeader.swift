import RobinHTML
import RobinLucide
import RobinStyle

/// Renders the responsive marketing-site navigation.
struct SiteHeader: Component {
  private let menuAnchor = try! Anchor("marketing-menu")
  private let appearanceAnchor = try! Anchor("marketing-appearance")

  var body: ComponentContent {
    Header {
      Link(Site.homeURL) {
        Image(source: "/robin-logo.png", alternateText: "").frame(width: 36, height: 36)
        Text { "Robin" }
      }.flex(align: .center, gap: .zero)
        .font(.emphasis, color: .foreground, decoration: TextDecoration.none)
        .font(.emphasis, color: .foreground, on: .dark)
      Stack {
        Navigation {
          MarketingLink { Link(Site.homeURL + "#features") { "Features" } }
          MarketingLink { Link(Site.homeURL + "#examples") { "Examples" } }
          MarketingLink { Link(Site.documentationURL) { "Docs" } }
          MarketingLink { Link(Site.sourceURL) { "GitHub" } }
        }.flex(align: .center, gap: .lg).hidden(on: .below(.md))
        MarketingPicker {
          Button(accessibilityLabel: "Appearance", command: .toggle("marketing-appearance")) {
            Icon(.sunMoon, size: 18)
          }
        }.anchor(appearanceAnchor)
        MarketingPopover {
          Popover(id: "marketing-appearance") {
            AppearanceControls()
          }
        }.position(at: appearanceAnchor)
        MarketingPicker {
          Button(accessibilityLabel: "Menu", command: .toggle("marketing-menu")) {
            Icon(.menu, size: 18)
          }
        }.anchor(menuAnchor).hidden(on: .md)
        MarketingPopover {
          Popover(id: "marketing-menu") {
            Navigation {
              MarketingMenuItem { Link(Site.homeURL + "#features") { "Features" } }
              MarketingMenuItem { Link(Site.homeURL + "#examples") { "Examples" } }
              MarketingMenuItem { Link(Site.documentationURL) { "Docs" } }
              MarketingMenuItem { Link(Site.sourceURL) { "GitHub" } }
            }.grid(columns: 1, gap: .sm)
          }
        }.position(at: menuAnchor).hidden(on: .md)
      }.flex(align: .center, gap: .sm).flex(align: .center, gap: .md, on: .md)
    }.flex(justify: .spaceBetween, align: .center, gap: .md)
  }
}

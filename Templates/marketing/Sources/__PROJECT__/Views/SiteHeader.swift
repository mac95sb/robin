import RobinHTML
import RobinLucide
import RobinStyle

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
          Link(Site.homeURL + "#features") { "Features" }.marketingLink()
          Link(Site.homeURL + "#examples") { "Examples" }.marketingLink()
          Link(Site.documentationURL) { "Docs" }.marketingLink()
          Link(Site.sourceURL) { "GitHub" }.marketingLink()
        }.flex(align: .center, gap: .lg).hidden(on: .below(.md))
        Button(accessibilityLabel: "Appearance", command: .toggle("marketing-appearance")) {
          Icon(.sunMoon, size: 18)
        }.starterPicker().anchor(appearanceAnchor)
        Popover(id: "marketing-appearance") {
          AppearanceControls()
        }.starterPopover().position(at: appearanceAnchor)
        Button(accessibilityLabel: "Menu", command: .toggle("marketing-menu")) {
          Icon(.menu, size: 18)
        }.starterPicker().anchor(menuAnchor).hidden(on: .md)
        Popover(id: "marketing-menu") {
          Navigation {
            Link(Site.homeURL + "#features") { "Features" }.starterMenuItem()
            Link(Site.homeURL + "#examples") { "Examples" }.starterMenuItem()
            Link(Site.documentationURL) { "Docs" }.starterMenuItem()
            Link(Site.sourceURL) { "GitHub" }.starterMenuItem()
          }.grid(columns: 1, gap: .sm)
        }.starterPopover().position(at: menuAnchor).hidden(on: .md)
      }.flex(align: .center, gap: .sm).flex(align: .center, gap: .md, on: .md)
    }.flex(justify: .spaceBetween, align: .center, gap: .md)
  }
}

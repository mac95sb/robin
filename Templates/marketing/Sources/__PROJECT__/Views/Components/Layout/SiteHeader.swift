import RobinHTML
import RobinLucide
import RobinStyle

/// Renders the responsive marketing-site navigation.
struct SiteHeader: Component {
  private let homeURL: String
  private let documentationURL: String

  init(homeURL: String, documentationURL: String) {
    self.homeURL = homeURL
    self.documentationURL = documentationURL
  }

  var body: ComponentContent {
    Header {
      Link(homeURL) {
        Image(source: "/robin-logo.png", alternateText: "Robin Logo").frame(width: 36, height: 36)
        Text { "Robin" }
      }
      .flex(align: .center, gap: .zero)
      .font(.emphasis, color: .foreground, decoration: TextDecoration.none)
      .font(color: .foreground, on: .dark)
      Stack {
        Navigation {
          NavigationLink(homeURL + "#features") { "Features" }
          NavigationLink(homeURL + "#examples") { "Examples" }
          NavigationLink(documentationURL) { "Docs" }
        }
        .flex(align: .center, gap: .lg).hidden(on: .below(.md))
        Popover {
          MenuTrigger(accessibilityLabel: "Appearance") {
            Icon(.sunMoon, size: 18)
          }
        } content: {
          MenuPopover {
            AppearanceMenu()
          }
        }
        Popover {
          MenuTrigger(accessibilityLabel: "Menu") {
            Icon(.menu, size: 18)
          }
        } content: {
          MenuPopover {
            Navigation {
              MenuLink(homeURL + "#features") { "Features" }
              MenuLink(homeURL + "#examples") { "Examples" }
              MenuLink(documentationURL) { "Docs" }
            }
            .grid(columns: 1, gap: .sm)
          }
        }
        .hidden(on: .md)
      }
      .flex(align: .center, gap: .sm).flex(align: .center, gap: .md, on: .md)
    }
    .flex(justify: .spaceBetween, align: .center, gap: .md)
  }
}

@_spi(Rendering) import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle
import RobinTheme

/// Introduces Robin and provides installation and example links.
struct HomePage: Page {
  let path = "/"
  private let homeURL = "https://robin.maclong.dev"
  private let documentationURL =
    "https://robin.maclong.dev/docs/reference/RobinCore/documentation/robincore/"
  var metadata: Metadata { Metadata(title: "The web, in Swift") }

  var body: ComponentContent {
    RobinPage {
      SiteHeader(homeURL: homeURL, documentationURL: documentationURL)
      Main {
        HeroSection(homeURL: homeURL, documentationURL: documentationURL)
        FeaturesSection()
        ExamplesSection()
        GettingStartedSection(documentationURL: documentationURL)
      }
      .grid(columns: 1, gap: .xxl)
      SiteFooter(documentationURL: documentationURL)
    }
  }
}

@_spi(Rendering) import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle

/// Introduces Robin and provides installation and example links.
struct HomePage: Page {
  let path = "/"
  var metadata: Metadata { Metadata(title: "The web, in Swift") }

  var body: ComponentContent {
    MarketingPage {
      SiteHeader()
      Main {
        Section {
          MarketingLabel { Text { "SWIFT-NATIVE, WEB-NATIVE." }.margin(.zero) }
          Heading {
            Text { "Build for the web." }
            Text { "Feel at home in Swift." }
          }.grid(columns: 1)
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
            .font(.heading, lineHeight: 70, letterSpacing: -2, on: .md)
          Text {
            "From your first page to a full-stack application. Compose your content, design, and server in one language—and let the browser do what it does best."
          }.margin(.zero).frame(maxWidth: 680).font(.body, color: .muted, lineHeight: 28)
            .font(.body, color: .muted, on: .dark)
          Stack {
            MarketingAction { Link(Site.documentationURL) { "Start building →" } }
            MarketingAction(primary: false) {
              Link(Site.homeURL + "#examples") { "See what ships ↓" }
            }
          }.flex(wrap: .wrap, align: .center, gap: .md)
          MarketingLabel {
            Text { "Typed components · Deterministic CSS · Optional browser capabilities" }.margin(
              .zero)
          }
        }.grid(columns: 1, gap: .lg)

        Section(id: "features") {
          Stack {
            MarketingLabel { Text { "LESS TO KEEP IN SYNC" }.margin(.zero) }
            MarketingTitle { Heading(.two) { "One language. A connected toolkit." } }
          }.grid(columns: 1, gap: .md)
          Stack {
            FeatureCard(
              number: "01", title: "Write Swift. Ship the web.",
              detail:
                "Compose semantic pages with typed components and trailing closures. Keep content, routes, and metadata alongside your application."
            )
            FeatureCard(
              number: "02", title: "A design system that travels.",
              detail:
                "Share color, spacing, and typography tokens. Express dark mode and responsive layouts through the CSS cascade."
            )
            FeatureCard(
              number: "03", title: "Start static. Grow from there.",
              detail:
                "Publish Markdown and static pages, or add controllers, persistence, passkeys, and realtime updates when your application needs them."
            )
          }.grid(columns: 1, gap: .lg).grid(columns: 3, gap: .lg, on: .lg)
        }.grid(columns: 1, gap: .lg)

        Section(id: "examples") {
          Stack {
            MarketingLabel { Text { "NOTHING UP ITS SLEEVE" }.margin(.zero) }
            MarketingTitle { Heading(.two) { "From a few lines to something real." } }
            Text {
              "Try the components, then switch files to inspect their Swift, generated HTML and CSS, and browser JavaScript. Shared page defaults are kept separately."
            }.margin(.zero).frame(maxWidth: 720)
          }.grid(columns: 1, gap: .md)
          ExampleGallery()
        }.grid(columns: 1, gap: .xxl)

        MarketingPanel {
          Section(id: "installation") {
            MarketingLabel { Text { "GET SET UP" }.margin(.zero) }
            MarketingTitle { Heading(.two) { "Installation" } }
            Text {
              "With mise installed, install the Robin CLI globally from GitHub:"
            }.margin(.zero)
            ExampleCode {
              CodeBlock("mise use -g github:mac95sb/robin", language: "shell", theme: .xcode)
            }
          }.grid(columns: 1, gap: .md).padding(.lg)
        }

        MarketingPanel {
          Section(id: "start-a-project") {
            MarketingLabel { Text { "MAKE IT YOURS" }.margin(.zero) }
            MarketingTitle { Heading(.two) { "Start a project" } }
            Text {
              "With the Robin CLI installed, create your site from the marketing template:"
            }.margin(.zero).frame(maxWidth: 680)
            ExampleCode {
              CodeBlock("robin init MySite --template marketing", language: "shell", theme: .xcode)
            }
            Text {
              "Make it a product site, a studio, or your own portfolio. Change the content and theme tokens; the same Robin components do the rest."
            }.margin(.zero).frame(maxWidth: 680)
            MarketingMenuItem {
              Link(Site.documentationURL) { "Explore the Swift DocC documentation →" }
            }
          }.grid(columns: 1, gap: .md).padding(.lg)
        }
      }.grid(columns: 1, gap: .xxl)
      Footer {
        MarketingRule()
        Stack {
          MarketingLabel { Text { "Built with Robin." }.margin(.zero) }
          Navigation {
            MarketingLink { Link(Site.documentationURL) { "Docs" }.margin(.zero) }
            MarketingLink {
              Link(Site.sourceURL + "/tree/main/Templates/marketing") { "Template source" }
            }
          }.flex(wrap: .wrap, gap: .lg)
        }.flex(wrap: .wrap, justify: .spaceBetween, gap: .md)
      }.grid(columns: 1, gap: .lg)
    }
  }
}

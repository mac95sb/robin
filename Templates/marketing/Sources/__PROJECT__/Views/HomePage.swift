@_spi(Rendering) import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle

struct HomePage: Page {
  let path = "/"
  var metadata: Metadata { Metadata(title: "The web, in Swift") }

  var body: ComponentContent {
    Stack {
      SiteHeader()
      Main {
        Section {
          Text { "SWIFT-NATIVE, WEB-NATIVE." }.margin(.zero).starterLink()
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
            Link(Site.documentationURL) { "Start building →" }.marketingAction()
            Link(Site.homeURL + "#examples") { "See what ships ↓" }.marketingAction(primary: false)
          }.flex(wrap: .wrap, align: .center, gap: .md)
          Text { "Typed components · Deterministic CSS · Optional browser capabilities" }
            .margin(.zero).starterLink()
        }.grid(columns: 1, gap: .lg)

        Section(id: "features") {
          Stack {
            Text { "LESS TO KEEP IN SYNC" }.margin(.zero).starterLink()
            Heading(.two) { "One language. A connected toolkit." }.starterTitle()
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
            Text { "NOTHING UP ITS SLEEVE" }.margin(.zero).starterLink()
            Heading(.two) { "From a few lines to something real." }.starterTitle()
            Text {
              "Try the components, then switch files to inspect their Swift, generated HTML and CSS, and browser JavaScript. Shared page defaults are kept separately."
            }.margin(.zero).frame(maxWidth: 720)
          }.grid(columns: 1, gap: .md)
          ExampleGallery()
        }.grid(columns: 1, gap: .xxl)

        Section(id: "installation") {
          Text { "GET SET UP" }.margin(.zero).starterLink()
          Heading(.two) { "Installation" }.starterTitle()
          Text {
            "With mise installed, install the Robin CLI globally from GitHub:"
          }.margin(.zero)
          CodeBlock("mise use -g github:mac95sb/robin", language: "shell", theme: .xcode)
            .exampleCode()
        }.grid(columns: 1, gap: .md).padding(.lg).marketingPanel()

        Section(id: "start-a-project") {
          Text { "MAKE IT YOURS" }.margin(.zero).starterLink()
          Heading(.two) { "Start a project" }.starterTitle()
          Text {
            "With the Robin CLI installed, create your site from the marketing template:"
          }.margin(.zero).frame(maxWidth: 680)
          CodeBlock("robin init MySite --template marketing", language: "shell", theme: .xcode)
            .exampleCode()
          Text {
            "Make it a product site, a studio, or your own portfolio. Change the content and theme tokens; the same Robin components do the rest."
          }.margin(.zero).frame(maxWidth: 680)
          Link(Site.documentationURL) { "Explore the Swift DocC documentation →" }.starterMenuItem()
        }.grid(columns: 1, gap: .md).padding(.lg).marketingPanel()
      }.grid(columns: 1, gap: .xxl)
      Footer {
        Stack {}.starterRule()
        Stack {
          Text { "Built with Robin." }.margin(.zero).starterLink()
          Navigation {
            Link(Site.documentationURL) { "Docs" }.margin(.zero).marketingLink()
            Link(Site.sourceURL + "/tree/main/Templates/marketing") { "Template source" }
              .marketingLink()
          }.flex(wrap: .wrap, gap: .lg)
        }.flex(wrap: .wrap, justify: .spaceBetween, gap: .md)
      }.grid(columns: 1, gap: .lg)
    }.starterPage()
  }
}

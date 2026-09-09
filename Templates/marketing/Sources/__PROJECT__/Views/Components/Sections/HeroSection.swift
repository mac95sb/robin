import RobinHTML
import RobinStyle
import RobinTheme

/// Introduces Robin and links to its documentation and examples.
struct HeroSection: Component {
  let homeURL: String
  let documentationURL: String

  var body: ComponentContent {
    Section {
      RobinLabel { Text { "SWIFT-NATIVE, WEB-NATIVE." }.margin(.zero) }
      Heading {
        Text { "Build for the web." }
        Text { "Feel at home in Swift." }
      }
      .grid(columns: 1)
      .margin(.zero)
      .font(.title, lineHeight: 38, letterSpacing: -1)
      .font(.heading, lineHeight: 70, letterSpacing: -2, on: .md)
      Text {
        """
        From your first page to a full-stack application.
        Compose your content, design, and server in one language.
        Let the browser do what it does best.
        """
      }
      .margin(.zero)
      .frame(maxWidth: 680)
      .font(.body, color: .muted, lineHeight: 28)
      .font(color: .muted, on: .dark)
      Stack {
        CallToAction(documentationURL) { "Start building →" }
        CallToAction(homeURL + "#examples", primary: false) { "See what ships ↓" }
      }
      .flex(wrap: .wrap, align: .center, gap: .md)
      RobinLabel {
        Text { "Typed components · Deterministic CSS · Optional browser capabilities" }
          .margin(.zero)
      }
    }
    .grid(columns: 1, gap: .lg)
  }
}

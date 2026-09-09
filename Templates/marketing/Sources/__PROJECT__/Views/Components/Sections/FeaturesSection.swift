import RobinHTML
import RobinStyle
import RobinTheme

/// Describes the framework's connected capabilities.
struct FeaturesSection: Component {
  var body: ComponentContent {
    Section(id: "features") {
      Stack {
        RobinLabel { Text { "LESS TO KEEP IN SYNC" }.margin(.zero) }
        RobinTitle { Heading(.two) { "One language. A connected toolkit." } }
      }
      .grid(columns: 1, gap: .md)
      Stack {
        FeatureCard(
          number: "01",
          title: "Write Swift. Ship the web.",
          detail: """
            Compose semantic pages with typed components and trailing closures.
            Keep content, routes, and metadata alongside your application.
            """
        )
        FeatureCard(
          number: "02",
          title: "A design system that travels.",
          detail: """
            Share color, spacing, and typography tokens.
            Express dark mode and responsive layouts through the CSS cascade.
            """
        )
        FeatureCard(
          number: "03",
          title: "Start static. Grow from there.",
          detail: """
            Publish Markdown and static pages, or add controllers, persistence,
            passkeys, and realtime updates when your application needs them.
            """
        )
      }
      .grid(columns: 1, gap: .lg)
      .grid(columns: 3, gap: .lg, on: .lg)
    }
    .grid(columns: 1, gap: .lg)
  }

  private struct FeatureCard: Component {
    let number: String
    let title: String
    let detail: String

    var body: ComponentContent {
      RobinPanel {
        Section {
          RobinLabel { Text { number }.margin(.zero) }
          Heading(.three) { title }.margin(.zero).font(.emphasis)
          Text { detail }.margin(.zero).font(.body, color: .muted)
            .font(color: .muted, on: .dark)
        }
        .grid(columns: 1, gap: .md).padding(.lg)
      }
    }
  }
}

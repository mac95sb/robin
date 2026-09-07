import RobinHTML
import RobinStyle

/// Presents one framework capability in the feature grid.
struct FeatureCard: Component {
  let number: String
  let title: String
  let detail: String

  var body: ComponentContent {
    MarketingPanel {
      Section {
        MarketingLabel { Text { number }.margin(.zero) }
        Heading(.three) { title }.margin(.zero).font(.emphasis)
        Text { detail }.margin(.zero).font(.body, color: .muted)
          .font(.body, color: .muted, on: .dark)
      }.grid(columns: 1, gap: .md).padding(.lg)
    }
  }
}

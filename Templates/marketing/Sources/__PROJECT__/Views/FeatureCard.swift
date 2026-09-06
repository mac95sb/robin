import RobinHTML
import RobinStyle

struct FeatureCard: Component {
  let number: String
  let title: String
  let detail: String

  var body: ComponentContent {
    Section {
      Text { number }.margin(.zero).starterLink()
      Heading(.three) { title }.margin(.zero).font(.emphasis)
      Text { detail }.margin(.zero).font(.body, color: .muted)
        .font(.body, color: .muted, on: .dark)
    }.grid(columns: 1, gap: .md).padding(.lg).marketingPanel()
  }
}

import RobinHTML
import RobinStyle

/// Demonstrates a static reusable card component.
struct WelcomeCard: Component {
  var body: ComponentContent {
    Stack {
      Heading(.three) { "A little less machinery." }
      Text { "A little more room for your ideas." }
    }
    .grid(columns: 1, gap: .sm)
    .padding(.lg)
    .border(color: .border, radius: .xl)
  }
  static let source = """
    import RobinHTML
    import RobinStyle

    /// Demonstrates a static reusable card component.
    struct WelcomeCard: Component {
      var body: ComponentContent {
        Stack {
          Heading(.three) { "A little less machinery." }
          Text { "A little more room for your ideas." }
        }
        .grid(columns: 1, gap: .sm)
        .padding(.lg)
        .border(color: .border, radius: .xl)
      }
    }
    """
}

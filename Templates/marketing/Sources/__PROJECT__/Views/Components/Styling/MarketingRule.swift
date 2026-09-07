import RobinHTML
import RobinStyle

/// Renders a subdued horizontal rule.
struct MarketingRule: Component {
  var body: ComponentContent {
    Stack {}.frame(height: 1).background(color: .border).background(color: .border, on: .dark)
  }
}

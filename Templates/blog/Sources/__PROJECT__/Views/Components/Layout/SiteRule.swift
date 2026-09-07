import RobinHTML
import RobinStyle

/// Draws the shared horizontal divider.
struct SiteRule: Component {
  var body: ComponentContent {
    Stack {}
      .frame(height: 1)
      .background(color: .border).background(color: .border, on: .dark)
  }
}

import RobinHTML
import RobinLucide
import RobinStyle

/// Presents the system, light, and dark appearance choices.
struct AppearanceMenu: Component {
  var body: ComponentContent {
    Stack {
      AppearanceOption(.system, accessibilityLabel: "System") {
        Icon(.monitor, size: 18)
        Text { "System" }
      }
      AppearanceOption(.light, accessibilityLabel: "Light") {
        Icon(.sun, size: 18)
        Text { "Light" }
      }
      AppearanceOption(.dark, accessibilityLabel: "Dark") {
        Icon(.moon, size: 18)
        Text { "Dark" }
      }
    }
    .grid(columns: 1, gap: .xs)
  }
}

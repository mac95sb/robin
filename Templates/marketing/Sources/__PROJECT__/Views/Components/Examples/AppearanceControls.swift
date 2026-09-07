import RobinHTML
import RobinLucide
import RobinStyle

/// Presents the system, light, and dark appearance choices.
struct AppearanceControls: Component {
  var body: ComponentContent {
    Stack {
      MarketingMenuItem {
        AppearanceButton(.system, accessibilityLabel: "System") {
          Icon(.monitor, size: 18)
          Text { "System" }
        }
      }
      MarketingMenuItem {
        AppearanceButton(.light, accessibilityLabel: "Light") {
          Icon(.sun, size: 18)
          Text { "Light" }
        }
      }
      MarketingMenuItem {
        AppearanceButton(.dark, accessibilityLabel: "Dark") {
          Icon(.moon, size: 18)
          Text { "Dark" }
        }
      }
    }.grid(columns: 1, gap: .xs)
  }
}

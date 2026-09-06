import RobinHTML
import RobinLucide
import RobinStyle

struct AppearanceControls: Component {
  var body: ComponentContent {
    Stack {
      AppearanceButton(.system, accessibilityLabel: "System") {
        Icon(.monitor, size: 18)
        Text { "System" }
      }.starterMenuItem()
      AppearanceButton(.light, accessibilityLabel: "Light") {
        Icon(.sun, size: 18)
        Text { "Light" }
      }.starterMenuItem()
      AppearanceButton(.dark, accessibilityLabel: "Dark") {
        Icon(.moon, size: 18)
        Text { "Dark" }
      }.starterMenuItem()
    }.grid(columns: 1, gap: .xs)
  }
}

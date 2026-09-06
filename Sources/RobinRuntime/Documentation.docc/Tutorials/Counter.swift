import RobinHTML
import RobinRuntime

struct Counter: Component {
  @State private var count = 0

  var body: ComponentContent {
    Stack {
      Text {
        "Count: "
        $count
      }
      Input(name: "count", value: $count, accessibilityLabel: "Count")
      Button(action: #action { count -= 10 }) { "−10" }
      Button(action: #action { count += 10 }) { "+10" }
      Button(action: #action { count = 0 }) { "Reset" }
    }
  }
}

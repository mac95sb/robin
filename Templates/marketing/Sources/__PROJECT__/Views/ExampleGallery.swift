@_spi(Rendering) import RobinBuild
import RobinHTML
import RobinLucide
import RobinRuntime
import RobinStyle

struct ExampleGallery: Component {
  @State private var selected = "Card"
  @State private var card = true
  @State private var counter = false
  @State private var toggle = false
  @State private var text = false
  private let anchor = try! Anchor("example-picker")

  var body: ComponentContent {
    Stack {
      Button(accessibilityLabel: "Choose example", command: .toggle("example-picker")) {
        Text { $selected }
        Icon(.chevronDown, size: 16)
      }.starterMenuItem().frame(width: 224).anchor(anchor)
      Popover(id: "example-picker") {
        Stack {
          Button(
            command: .hide("example-picker"),
            action: #action {
              selected = "Card"
              card = true
              counter = false
              toggle = false
              text = false
            }
          ) { "Card" }.starterMenuItem()
          Button(
            command: .hide("example-picker"),
            action: #action {
              selected = "Counter"
              card = false
              counter = true
              toggle = false
              text = false
            }
          ) { "Counter" }.starterMenuItem()
          Button(
            command: .hide("example-picker"),
            action: #action {
              selected = "Boolean toggle"
              card = false
              counter = false
              toggle = true
              text = false
            }
          ) { "Boolean toggle" }.starterMenuItem()
          Button(
            command: .hide("example-picker"),
            action: #action {
              selected = "Text binding"
              card = false
              counter = false
              toggle = false
              text = true
            }
          ) { "Text binding" }.starterMenuItem()
        }.grid(columns: 1, gap: .xs)
      }.starterPopover().position(at: anchor)
      CodeExample(
        id: "card", title: "A card, composed.",
        description: "Semantic HTML and reusable styles. This component needs no JavaScript.",
        source: WelcomeCard.source, preview: WelcomeCard(), javascript: nil
      ).visible($card)
      CodeExample(
        id: "counter", title: "A little state. An immediate response.",
        description: "Increment, decrement, type a number, or reset.",
        source: CounterDemo.source, preview: CounterDemo(), javascript: ClientStateRuntime.source
      ).visible($counter)
      CodeExample(
        id: "toggle", title: "Show just what you need.",
        description: "A Boolean controls the visibility of additional content.",
        source: ToggleDemo.source, preview: ToggleDemo(), javascript: ClientStateRuntime.source
      ).visible($toggle)
      CodeExample(
        id: "text", title: "Your words, reflected instantly.",
        description: "A text input and its greeting share one string binding.",
        source: TextDemo.source, preview: TextDemo(), javascript: ClientStateRuntime.source
      ).visible($text)
    }.grid(columns: 1, gap: .lg)
  }
}

@_spi(Rendering) import RobinBuild
import RobinHTML
import RobinLucide
import RobinRuntime
import RobinStyle

/// Lets visitors switch between the marketing site’s component examples.
struct ExampleGallery: Component {
  @State private var selected = "Card"
  @State private var card = true
  @State private var counter = false
  @State private var toggle = false
  @State private var text = false

  var body: ComponentContent {
    Stack {
      Popover {
        MenuButton(accessibilityLabel: "Choose example") {
          Text { $selected }
          Icon(.chevronDown, size: 16)
        }
        .flex(justify: .spaceBetween, align: .center, gap: .sm)
        .frame(width: 138)
        .border(color: .border, width: 1, radius: .sm)
        .border(color: .border, width: 1, radius: .sm, on: .dark)
      } content: {
        MenuPopover {
          Stack {
            MenuButton(
              command: .dismiss,
              action: #action {
                selected = "Card"
                card = true
                counter = false
                toggle = false
                text = false
              }
            ) { "Card" }
            MenuButton(
              command: .dismiss,
              action: #action {
                selected = "Counter"
                card = false
                counter = true
                toggle = false
                text = false
              }
            ) { "Counter" }
            MenuButton(
              command: .dismiss,
              action: #action {
                selected = "Toggle"
                card = false
                counter = false
                toggle = true
                text = false
              }
            ) { "Toggle" }
            MenuButton(
              command: .dismiss,
              action: #action {
                selected = "Binding"
                card = false
                counter = false
                toggle = false
                text = true
              }
            ) { "Binding" }
          }
          .grid(columns: 1, gap: .xs)
        }
        .frame(width: 120, minWidth: 0)
      }
      CodeExample(
        title: "A card, composed.",
        description: """
          Semantic HTML and reusable styles. This component needs no JavaScript.
          """,
        source: WelcomeCard.source,
        preview: WelcomeCard(),
        javascript: nil
      )
      .visible($card)
      CodeExample(
        title: "A little state. An immediate response.",
        description: "Increment, decrement, type a number, or reset.",
        source: CounterDemo.source,
        preview: CounterDemo(),
        javascript: ClientStateRuntime.source
      )
      .visible($counter)
      CodeExample(
        title: "Show just what you need.",
        description: "A Boolean controls the visibility of additional content.",
        source: ToggleDemo.source,
        preview: ToggleDemo(),
        javascript: ClientStateRuntime.source
      )
      .visible($toggle)
      CodeExample(
        title: "Your words, reflected instantly.",
        description: "A text input and its greeting share one string binding.",
        source: TextDemo.source,
        preview: TextDemo(),
        javascript: ClientStateRuntime.source
      )
      .visible($text)
    }
    .grid(columns: 1, gap: .lg)
  }
}

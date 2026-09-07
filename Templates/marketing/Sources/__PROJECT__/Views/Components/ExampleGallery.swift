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
  private let anchor = try! Anchor("example-picker")

  var body: ComponentContent {
    Stack {
      MarketingMenuItem {
        Button(accessibilityLabel: "Choose example", command: .toggle("example-picker")) {
          Text { $selected }
          Icon(.chevronDown, size: 16)
        }
      }.flex(justify: .spaceBetween, align: .center, gap: .sm)
        .frame(width: 138).border(color: .border, width: 1, radius: .sm)
        .border(color: .border, width: 1, radius: .sm, on: .dark).anchor(anchor)
      MarketingPopover {
        Popover(id: "example-picker") {
          Stack {
            MarketingMenuItem {
              Button(
                command: .hide("example-picker"),
                action: #action {
                  selected = "Card"
                  card = true
                  counter = false
                  toggle = false
                  text = false
                }
              ) { "Card" }
            }
            MarketingMenuItem {
              Button(
                command: .hide("example-picker"),
                action: #action {
                  selected = "Counter"
                  card = false
                  counter = true
                  toggle = false
                  text = false
                }
              ) { "Counter" }
            }
            MarketingMenuItem {
              Button(
                command: .hide("example-picker"),
                action: #action {
                  selected = "Toggle"
                  card = false
                  counter = false
                  toggle = true
                  text = false
                }
              ) { "Toggle" }
            }
            MarketingMenuItem {
              Button(
                command: .hide("example-picker"),
                action: #action {
                  selected = "Binding"
                  card = false
                  counter = false
                  toggle = false
                  text = true
                }
              ) { "Binding" }
            }
          }.grid(columns: 1, gap: .xs)
        }
      }.frame(width: 120, minWidth: 0).position(at: anchor)
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

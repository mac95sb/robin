import RobinHTML
import RobinServer
import RobinStyle
import RobinTheme

/// Demonstrates a native GET form rendered by the server.
struct GreetingSection: Component {
  @Query("greeting") private var name: String?

  var body: ComponentContent {
    RobinPanel {
      Section {
        RobinTitle { Heading(.three) { "A server-rendered response." } }
        Text {
          """
          Submit this native form and the server renders your greeting in a complete
          document.
          """
        }
        .margin(.zero)
        Form(action: "/", method: .get) {
          Input(name: "greeting", accessibilityLabel: "Your name")
          Button(.submit) { "Say hello" }
        }
        .flex(wrap: .wrap, gap: .sm)
        if let name {
          RobinLabel { Text { "Hello, \(name)!" }.margin(.zero) }
        }
      }
      .grid(columns: 1, gap: .md)
      .padding(.lg)
    }
  }
}

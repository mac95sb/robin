import RobinHTML
import RobinRuntime
import RobinStyle

/// Demonstrates a text binding shared by an input and displayed content.
struct TextDemo: Component {
  @State private var name = "Robin"

  var body: ComponentContent {
    Stack {
      Label(for: "demo-name") { "Your name" }.font(.emphasis)
      Input(name: "name", value: $name, id: "demo-name", accessibilityLabel: "Your name")
        .padding(.md).font(.body, color: .foreground)
        .font(color: .foreground, on: .dark)
        .background(color: .surface).background(color: .surface, on: .dark)
        .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
        .border(color: .accent, radius: .md, on: .hover || .focus)
        .border(color: .accent, radius: .md, on: .dark && (.hover || .focus))
      Text {
        "Hello, "
        $name
        "!"
      }
    }
    .grid(columns: 1, gap: .md)
  }
  static let source = """
    import RobinHTML
    import RobinRuntime
    import RobinStyle

    /// Demonstrates a text binding shared by an input and displayed content.
    struct TextDemo: Component {
      @State private var name = "Robin"

      var body: ComponentContent {
        Stack {
          Label(for: "demo-name") { "Your name" }.font(.emphasis)
          Input(name: "name", value: $name, id: "demo-name", accessibilityLabel: "Your name")
            .padding(.md).font(.body, color: .foreground)
            .font(color: .foreground, on: .dark)
            .background(color: .surface).background(color: .surface, on: .dark)
            .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
            .border(color: .accent, radius: .md, on: .hover || .focus)
            .border(color: .accent, radius: .md, on: .dark && (.hover || .focus))
          Text {
            "Hello, "
            $name
            "!"
          }
        }.grid(columns: 1, gap: .md)
      }
    }
    """
}

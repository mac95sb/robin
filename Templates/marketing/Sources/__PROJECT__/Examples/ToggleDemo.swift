import RobinHTML
import RobinRuntime
import RobinStyle

struct ToggleDemo: Component {
  @State private var showDetails = false

  var body: ComponentContent {
    Stack {
      Button(action: #action { showDetails.toggle() }) { "Toggle details" }
        .padding(.md).font(.emphasis, color: .foreground)
        .font(.emphasis, color: .foreground, on: .dark)
        .background(color: .cardHover).background(color: .cardHover, on: .dark)
        .border(color: .border, radius: .md)
        .border(color: .accent, radius: .md, on: .hover || .focus)
        .border(color: .accent, radius: .md, on: .dark && (.hover || .focus))
      Text { "A little more detail, just when you need it." }.visible($showDetails)
    }.grid(columns: 1, gap: .md)
  }
  static let source = """
    import RobinHTML
    import RobinRuntime
    import RobinStyle

    struct ToggleDemo: Component {
      @State private var showDetails = false

      var body: ComponentContent {
        Stack {
          Button(action: #action { showDetails.toggle() }) { "Toggle details" }
            .padding(.md).font(.emphasis, color: .foreground)
            .font(.emphasis, color: .foreground, on: .dark)
            .background(color: .cardHover).background(color: .cardHover, on: .dark)
            .border(color: .border, radius: .md)
            .border(color: .accent, radius: .md, on: .hover || .focus)
            .border(color: .accent, radius: .md, on: .dark && (.hover || .focus))
          Text { "A little more detail, just when you need it." }.visible($showDetails)
        }.grid(columns: 1, gap: .md)
      }
    }
    """
}

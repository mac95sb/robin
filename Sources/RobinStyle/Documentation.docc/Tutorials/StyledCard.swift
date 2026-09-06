import RobinHTML
import RobinStyle

struct WelcomeCard: Component {
  var body: ComponentContent {
    Stack {
      Heading { "Welcome" }
      Text { "Resize the window to change the padding." }
      Link("/about") { "About this site" }
        .font(.body, color: .accent)
        .font(.body, color: .foreground, on: .hover)
    }
    .grid(columns: 1, gap: .md)
    .padding(.sm)
    .padding(.lg, on: .md)
    .background(color: .background)
    .border(color: .border, width: 1, radius: .lg)
  }
}

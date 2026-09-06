import RobinHTML
import RobinStyle

struct UsernameEditor: Component {
  var username: String = ""

  var body: ComponentContent {
    Form(action: "/api/v1/username") {
      Label(for: "username") { "Username" }.starterLink()
      Input(name: "username", value: username, id: "username", accessibilityLabel: "Username")
        .font(.body, color: .foreground).font(.body, color: .foreground, on: .dark)
        .padding(.sm).frame(minWidth: 0)
        .background(color: .surface).background(color: .surface, on: .dark)
        .border(color: .border, radius: .sm).border(color: .border, radius: .sm, on: .dark)
      Text {
        "3–24 letters, numbers, or underscores. Usernames are unique and stored in lowercase."
      }
      .margin(.zero).starterLink()
      Stack { Button(.submit) { "Save username" }.starterButton() }.flex()
    }.grid(columns: 1, gap: .sm).padding(.sm)
  }
}

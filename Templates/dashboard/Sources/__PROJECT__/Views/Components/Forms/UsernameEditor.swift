import RobinHTML
import RobinStyle

/// Renders the form for choosing a chat username.
struct UsernameEditor: Component {
  var username: String = ""

  var body: ComponentContent {
    Form(action: "/api/v1/username") {
      DashboardLabel { Label(for: "username") { "Username" } }
      Input(name: "username", value: username, id: "username", accessibilityLabel: "Username")
        .font(.body, color: .foreground).font(.body, color: .foreground, on: .dark)
        .padding(.sm).frame(minWidth: 0)
        .background(color: .surface).background(color: .surface, on: .dark)
        .border(color: .border, radius: .sm).border(color: .border, radius: .sm, on: .dark)
      DashboardLabel {
        Text {
          "3–24 letters, numbers, or underscores. Usernames are unique and stored in lowercase."
        }.margin(.zero)
      }
      Stack { PrimaryButton { Button(.submit) { "Save username" } } }.flex()
    }.grid(columns: 1, gap: .sm).padding(.sm)
  }
}

import RobinHTML
import RobinStyle

struct AccountPanel: Component {
  var body: ComponentContent {
    Section {
      Heading(.two) { "Your workspace" }.font(.body).margin(.zero)
      Text { "Sign in to manage your notes and join the conversation." }.margin(.zero).starterLink()
      Stack {}.starterRule()
      Stack {
        Button(id: "register") { "Create account" }.starterButton()
        Button(id: "login") { "Sign in with a passkey" }.starterSecondaryButton()
      }.flex(wrap: .wrap, gap: .sm)
      Text { "Secure sign-in with your device. No password to remember." }.margin(.zero)
        .starterLink()
    }.grid(columns: 1, gap: .md).starterPanel()
  }
}

import RobinHTML
import RobinStyle

/// Presents passkey registration and sign-in actions.
struct AccountPanel: Component {
  var body: ComponentContent {
    DashboardPanel {
      Section {
        Heading(.two) { "Your workspace" }.font(.body).margin(.zero)
        DashboardLabel {
          Text { "Sign in to manage your notes and join the conversation." }.margin(.zero)
        }
        DashboardRule()
        Stack {
          PrimaryButton { Button(id: "register") { "Create account" } }
          SecondaryButton { Button(id: "login") { "Sign in with a passkey" } }
        }.flex(wrap: .wrap, gap: .sm)
        DashboardLabel {
          Text { "Secure sign-in with your device. No password to remember." }.margin(.zero)
        }
      }.grid(columns: 1, gap: .md)
    }
  }
}

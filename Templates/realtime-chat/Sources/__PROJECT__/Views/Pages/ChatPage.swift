import RobinContent
import RobinCore
import RobinHTML
import RobinServer
import RobinStyle

struct ChatPage: Page {
  let path = "/"
  @RequestValue(MessageListKey.self) private var messages: [ChatMessage]

  var metadata: Metadata { Metadata(title: t("dashboard"), description: t("intro")) }

  var body: ComponentContent {
    Main {
      Section {
        Heading(.two) { "Your account" }
        Button(id: "register") { "Create account with a passkey" }
        Button(id: "login") { "Sign in with a passkey" }
        Form(action: "/api/v1/auth/logout") { Button(.submit) { "Sign out" } }
        Text {
          "Passkeys need JavaScript. Once signed in, notes and history remain readable without it."
        }
      }
      Heading { t("title") }
      Text { t("intro") }
      Section {
        Heading(.two) { "Messages" }
        Text(id: "chat-status") { "Connecting" }
        List(id: "chat-messages") {
          for message in messages {
            ListItem { "\(message.authorID): \(message.text)" }
          }
        }
        Form(id: "chat-form") {
          Input(name: "message", id: "chat-input", accessibilityLabel: "Message")
          Button(.submit) { "Send" }
        }
      }
    }
    .frame(maxWidth: 720)
    .margin(.lg)
  }
}

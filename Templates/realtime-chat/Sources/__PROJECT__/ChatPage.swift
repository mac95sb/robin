import RobinCore
import RobinHTML
import RobinServer
import RobinStyle
import RobinTheme

/// Shows the authenticated shared conversation.
struct ChatPage: Page {
  let path = "/"
  @RequestValue(SignedInKey.self) private var signedIn: Bool
  @RequestValue(MessageListKey.self) private var messages: [ChatMessage]

  var metadata: Metadata {
    Metadata(title: "Chat", description: "An authenticated realtime conversation.")
  }

  var body: ComponentContent {
    RobinPage {
      Header { Heading { "__PROJECT__" }.margin(.zero) }
      Main {
        Heading(.two) { "Realtime chat" }
        Text { "Messages persist in SQLite and update over a WebSocket connection." }
        if signedIn {
          Stack {
            Text(id: "chat-status") { "Connecting" }
            Form(action: "/api/v1/auth/logout") { Button(.submit) { "Sign out" } }
          }
          .flex(justify: .spaceBetween, align: .center, gap: .md)
          List(id: "chat-messages") {
            for message in messages {
              ListItem(title: message.sentAt.ISO8601Format()) {
                "\(message.authorID): \(message.text)"
              }
            }
          }
          .listMarker(.none).padding(.lg).border(color: .border, radius: .md)
          Form(id: "chat-form") {
            Input(name: "message", id: "chat-input", accessibilityLabel: "Message")
              .padding(.sm).flexItem(grow: 1)
            Button(.submit) { "Send" }.padding(.sm).background(color: .accent)
          }
          .flex(gap: .sm)
        } else {
          Section {
            Heading(.three) { "Sign in to join" }
            Stack {
              Button(id: "register") { "Create account" }
              Button(id: "login") { "Sign in with a passkey" }
            }
            .flex(wrap: .wrap, gap: .sm)
          }
          .padding(.lg).border(color: .border, radius: .md)
        }
      }
      .grid(columns: 1, gap: .md)
    }
  }
}

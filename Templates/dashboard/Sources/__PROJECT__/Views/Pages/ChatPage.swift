import RobinContent
import RobinCore
import RobinHTML
import RobinLucide
import RobinServer
import RobinStyle

/// Shows the authenticated realtime conversation.
struct ChatPage: Page {
  let path = "/conversations"
  @RequestValue(SignedInKey.self) private var signedIn: Bool
  @RequestValue(UsernameKey.self) private var username: String?
  @RequestValue(AuthorNamesKey.self) private var authorNames: [String: String]
  @RequestValue(MessageListKey.self) private var messages: [ChatMessage]

  var metadata: Metadata {
    Metadata(title: t("conversations"), description: t("conversationsOverview"))
  }

  var body: ComponentContent {
    DashboardPageLayout {
      SiteHeader()
      Main {
        Stack {
          DashboardLabel { Text { "WORKSPACE / CONVERSATIONS" }.margin(.zero) }
          Heading { t("conversations") }
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
            .font(.title, lineHeight: 38, letterSpacing: -1, on: .md)
          Text { t("conversationsOverview") }
            .margin(.zero).frame(maxWidth: 560)
            .font(.body, color: .muted, lineHeight: 28)
            .font(.body, color: .muted, lineHeight: 28, on: .dark)
        }.grid(columns: 1, gap: .sm)

        if !signedIn {
          AccountPanel()
        } else if username == nil {
          DashboardPanel {
            Section {
              DashboardTitle { Heading(.two) { "Choose your username" } }
              UsernameEditor()
              Form(action: "/api/v1/auth/logout") {
                SecondaryButton { Button(.submit) { "Sign out" } }
              }
            }.grid(columns: 1, gap: .md)
          }
        } else {
          DashboardPanel {
            Section {
              Stack {
                Stack {
                  Icon(.messagesSquare, size: 22)
                  Stack {
                    Heading(.two) { t("general") }.font(.emphasis).margin(.zero)
                    DashboardLabel { Text { t("sharedConversation") }.margin(.zero) }
                  }.grid(columns: 1, gap: .xs)
                }.flex(align: .center, gap: .md)
                Stack {
                  DashboardLabel { Text(id: "chat-status") { "Connecting" }.margin(.zero) }
                    .padding(.sm).background(color: .background).background(
                      color: .background, on: .dark
                    )
                    .border(color: .border, width: 0, radius: .md)
                  Form(action: "/api/v1/auth/logout") {
                    SecondaryButton { Button(.submit) { "Sign out" } }
                  }
                }.flex(wrap: .wrap, align: .center, gap: .md)
              }.flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
              DashboardRule()
              Disclosure {
                "@\(username ?? "") · Change username"
              } content: {
                UsernameEditor(username: username ?? "")
              }
              List(id: "chat-messages") {
                for message in messages {
                  ListItem(title: message.timestamp) {
                    "@\(authorNames[message.authorID] ?? "Member"): \(message.text)"
                  }
                }
              }.frame(minHeight: 280).margin(.zero).padding(.lg)
                .flex(direction: .column, gap: .lg).listMarker(.none)
                .font(.body, lineHeight: 30)
                .background(color: .background).background(color: .background, on: .dark)
                .border(color: .border, width: 0, radius: .lg)
              Form(id: "chat-form") {
                Input(name: "message", id: "chat-input", accessibilityLabel: "Message")
                  .font(.body, color: .foreground).font(.body, color: .foreground, on: .dark)
                  .padding(.md).frame(minWidth: 0).flexItem(grow: 1, basis: 120)
                  .background(color: .surface).background(color: .surface, on: .dark)
                  .border(color: .border, radius: .sm).border(
                    color: .border, radius: .sm, on: .dark)
                PrimaryButton {
                  Button(.submit, accessibilityLabel: "Send message") {
                    Icon(.arrowUp, size: 18)
                    Text { t("send") }
                  }
                }.flex(align: .center, gap: .sm)
              }.flex(wrap: .wrap, gap: .sm)
            }.grid(columns: 1, gap: .md)
          }
          .frame(minWidth: 0)
        }
      }.grid(columns: 1, gap: .lg)
      SiteFooter()
    }
  }
}

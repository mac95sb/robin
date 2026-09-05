import RobinContent
import RobinCore
import RobinHTML
import RobinServer
import RobinStyle

struct DashboardPage: Page {
  let path = "/"
  @RequestValue(NoteListKey.self) private var notes: [Note]

  var metadata: Metadata {
    Metadata(title: t("dashboard"), description: t("intro"))
  }

  var body: ComponentContent {
    Header {
      Navigation {
        Link(localizedPath("/")) { t("dashboard") }
        Link(localizedPath("/about")) { t("about") }
      }
    }
    .padding(.md)

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
        Heading(.two) { t("appModel") }
        Stack {
          Text { t("serverRenderedPages") }
          Text { t("typedRoutes") }
          Text { t("sharedMetadata") }
        }
        .grid(columns: 1, gap: .md)
        .grid(columns: 3, gap: .lg, on: .md)
      }
      Section {
        Heading(.two) { t("notes") }
        NoteEditor(
          form: NoteForm(), action: "/api/v1/notes", identifier: "content", button: t("addNote"))
        for note in notes {
          Article {
            NoteEditor(
              form: NoteForm(content: note.content), action: "/api/v1/notes/\(note.id)",
              identifier: "note-\(note.id)", button: t("saveNote"))
            Form(action: "/api/v1/notes/\(note.id)/delete") {
              Button(.submit) { t("deleteNote") }
            }
          }
        }
      }
    }
    .frame(maxWidth: 960)
    .margin(.lg)
  }
}

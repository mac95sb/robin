import RobinContent
import RobinCore
import RobinHTML
import RobinStyle

struct DashboardPage: Page {
  let path = "/"
  let notes: NotesStore

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
        Form(action: "/api/v1/notes") {
          TextArea(name: "content", accessibilityLabel: t("notePlaceholder"))
          Button(.submit) { t("addNote") }
        }
        for note in notes.all() {
          Article {
            Form(action: "/api/v1/notes/\(note.id)") {
              TextArea(
                name: "content", value: note.content, accessibilityLabel: t("notePlaceholder"))
              Button(.submit) { t("saveNote") }
            }
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

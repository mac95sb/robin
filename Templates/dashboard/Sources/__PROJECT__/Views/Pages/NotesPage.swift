import RobinContent
import RobinCore
import RobinHTML
import RobinLucide
import RobinServer
import RobinStyle

struct NotesPage: Page {
  let path = "/notes"
  @RequestValue(SignedInKey.self) private var signedIn: Bool
  @RequestValue(NoteListKey.self) private var notes: [Note]

  var metadata: Metadata {
    Metadata(title: t("notes"), description: t("notesIntro"))
  }

  var body: ComponentContent {
    Stack {
      SiteHeader()
      Main {
        Stack {
          Text { "WORKSPACE / NOTES" }.margin(.zero).starterLink()
          Heading { t("notes") }
            .margin(.zero).font(.title, lineHeight: 38, letterSpacing: -1)
            .font(.title, lineHeight: 38, letterSpacing: -1, on: .md)
          Text { t("notesIntro") }
            .margin(.zero).frame(maxWidth: 560)
            .font(.body, color: .muted, lineHeight: 28)
            .font(.body, color: .muted, lineHeight: 28, on: .dark)
        }.grid(columns: 1, gap: .sm)

        if !signedIn {
          AccountPanel()
        } else {
          Section(id: "notes") {
            Stack {
              Stack {
                Icon(.lockKeyhole, size: 16)
                Text { t("privateCollection") }.margin(.zero).starterLink()
              }.flex(align: .center, gap: .sm)
              Stack {
                Text { "\(notes.count) saved" }.margin(.zero).starterLink()
                Form(action: "/api/v1/auth/logout") {
                  Button(.submit) { "Sign out" }.starterSecondaryButton()
                }
              }.flex(wrap: .wrap, align: .center, gap: .md)
            }.flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
            Section {
              Stack {
                Icon(.squarePen, size: 20)
                Heading(.two) { t("captureIdea") }.margin(.zero).font(.emphasis)
              }.flex(align: .center, gap: .sm)
              NoteEditor(
                form: NoteForm(), action: "/api/v1/notes", identifier: "content",
                button: t("addNote"))
            }.grid(columns: 1, gap: .md).starterPanel()
            Stack {
              for note in notes {
                Article {
                  Stack {
                    Text { "NOTE / \(note.id)" }.margin(.zero).starterLink()
                    Form(action: "/api/v1/notes/\(note.id)/delete") {
                      Button(.submit, accessibilityLabel: t("deleteNote")) {
                        Icon(.trash, size: 16)
                      }.starterSecondaryButton()
                    }
                  }.flex(justify: .spaceBetween, align: .center, gap: .sm)
                  NoteEditor(
                    form: NoteForm(content: note.content), action: "/api/v1/notes/\(note.id)",
                    identifier: "note-\(note.id)", button: t("saveNote"))
                }.grid(columns: 1, gap: .md).starterPanel().frame(minWidth: 0)
              }
            }.grid(columns: 1, gap: .md).grid(columns: 2, gap: .md, on: .md)
          }.grid(columns: 1, gap: .lg).frame(minWidth: 0)
        }

      }.grid(columns: 1, gap: .lg)
      SiteFooter()
    }.starterPage()
  }
}

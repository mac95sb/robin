import RobinContent
import RobinCore
import RobinHTML
import RobinLucide
import RobinServer
import RobinStyle

/// Shows and edits the authenticated person’s private notes.
struct NotesPage: Page {
  let path = "/notes"
  @RequestValue(SignedInKey.self) private var signedIn: Bool
  @RequestValue(NoteListKey.self) private var notes: [Note]

  var metadata: Metadata {
    Metadata(title: t("notes"), description: t("notesIntro"))
  }

  var body: ComponentContent {
    DashboardPageLayout {
      SiteHeader()
      Main {
        Stack {
          DashboardLabel { Text { "WORKSPACE / NOTES" }.margin(.zero) }
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
                DashboardLabel { Text { t("privateCollection") }.margin(.zero) }
              }.flex(align: .center, gap: .sm)
              Stack {
                DashboardLabel { Text { "\(notes.count) saved" }.margin(.zero) }
                Form(action: "/api/v1/auth/logout") {
                  SecondaryButton { Button(.submit) { "Sign out" } }
                }
              }.flex(wrap: .wrap, align: .center, gap: .md)
            }.flex(wrap: .wrap, justify: .spaceBetween, align: .center, gap: .md)
            DashboardPanel {
              Section {
                Stack {
                  Icon(.squarePen, size: 20)
                  Heading(.two) { t("captureIdea") }.margin(.zero).font(.emphasis)
                }.flex(align: .center, gap: .sm)
                NoteEditor(
                  form: NoteForm(), action: "/api/v1/notes", identifier: "content",
                  button: t("addNote"))
              }.grid(columns: 1, gap: .md)
            }
            Stack {
              for note in notes {
                DashboardPanel {
                  Article {
                    Stack {
                      DashboardLabel { Text { "NOTE / \(note.id)" }.margin(.zero) }
                      Form(action: "/api/v1/notes/\(note.id)/delete") {
                        SecondaryButton {
                          Button(.submit, accessibilityLabel: t("deleteNote")) {
                            Icon(.trash, size: 16)
                          }
                        }
                      }
                    }.flex(justify: .spaceBetween, align: .center, gap: .sm)
                    NoteEditor(
                      form: NoteForm(content: note.content), action: "/api/v1/notes/\(note.id)",
                      identifier: "note-\(note.id)", button: t("saveNote"))
                  }.grid(columns: 1, gap: .md)
                }.frame(minWidth: 0)
              }
            }.grid(columns: 1, gap: .md).grid(columns: 2, gap: .md, on: .md)
          }.grid(columns: 1, gap: .lg).frame(minWidth: 0)
        }

      }.grid(columns: 1, gap: .lg)
      SiteFooter()
    }
  }
}

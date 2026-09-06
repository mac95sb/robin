import RobinForms
import RobinHTML
import RobinStyle

struct NoteEditor: Component {
  let form: NoteForm
  let action: String
  let identifier: String
  let button: String

  var body: ComponentContent {
    FormErrorSummary(form.validationErrors)
    RobinHTML.Form(action: action) {
      form.$content.input(id: identifier, multiline: true) { control in
        control.font(.body, color: .foreground, lineHeight: 26).font(
          .body, color: .foreground, lineHeight: 26, on: .dark
        )
        .padding(.md).frame(minWidth: 0, minHeight: 112)
        .background(color: .background).background(color: .background, on: .dark)
        .border(color: .border, radius: .sm).border(color: .border, radius: .sm, on: .dark)
        .border(color: .accent, radius: .sm, on: .focus)
      }
      Stack { Button(.submit) { button }.starterButton() }.flex()
    }.grid(columns: 1, gap: .md)
  }
}

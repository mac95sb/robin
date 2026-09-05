import RobinForms
import RobinHTML

struct NoteEditor: Component {
  let form: NoteForm
  let action: String
  let identifier: String
  let button: String

  var body: ComponentContent {
    FormErrorSummary(form.validationErrors)
    RobinHTML.Form(action: action) {
      form.$content.input(id: identifier)
      Button(.submit) { button }
    }
  }
}

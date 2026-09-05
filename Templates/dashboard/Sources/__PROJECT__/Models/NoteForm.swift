import Foundation
import RobinForms

@FormModel
struct NoteForm {
  @Field(
    "content", label: "Note", required: true, maximumLength: 4_096,
    validate: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Write a note." : nil }
  )
  var content = ""

  init() {}
  init(content: String) { self.content = content }
}

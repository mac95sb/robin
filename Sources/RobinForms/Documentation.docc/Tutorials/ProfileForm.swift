import RobinForms
import RobinHTML

@FormModel
struct ProfileForm {
  @Field("name", label: "Your name", required: true, maximumLength: 80)
  var name = ""
}

let values = try FormValues.urlEncoded(Array("name=Robin".utf8))
let profile = try ProfileForm.decode(from: values).validated()
assert(profile.name == "Robin")

let invalid = try ProfileForm.decode(from: FormValues.urlEncoded(Array("name=".utf8)))
let redisplayedForm = Form {
  FormErrorSummary(invalid.validationErrors)
  invalid.$name
  Button(.submit) { "Save" }
}
assert(!invalid.validationErrors.isEmpty)

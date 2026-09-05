import Foundation
import RobinForms
@_spi(Rendering) import RobinHTML
import Testing

@FormModel
private struct ContactForm {
  @Field("name", label: "Your name", required: true, minimumLength: 2, maximumLength: 30)
  var name = ""
  @Field("age", validate: { $0 >= 18 ? nil : "You must be at least 18." }) var age = 18
}

@Suite struct FormTests {
  @Test func decodesNativeAndJSONValuesWithSharedValidation() throws {
    let native = ContactForm.decode(from: try .urlEncoded(Array("name=Robin&age=24".utf8)))
    let json = ContactForm.decode(from: try .json(Array(#"{"name":"Robin","age":24}"#.utf8)))
    #expect(try native.validated().name == json.validated().name)
    #expect(native.age == 24)
    let invalid = ContactForm.decode(from: try .urlEncoded(Array("name=x&age=17".utf8)))
    #expect(invalid.validationErrors.count == 2)
    #expect(throws: FieldValidationError.self) { try invalid.validated() }
    let html = try HTMLRenderer.render(
      RobinHTML.Form {
        invalid.$name
        invalid.$age
      })
    #expect(html.contains("required"))
    #expect(html.contains("minlength=\"2\""))
    #expect(html.contains("maxlength=\"30\""))
    #expect(html.contains("value=\"x\""))
    #expect(html.contains("aria-describedby=\"name-error\""))
    #expect(html.contains("aria-invalid=\"true\""))
    #expect(
      try HTMLRenderer.render(FormErrorSummary(invalid.validationErrors)).contains("href=\"#name\"")
    )
  }

  @Test func rejectsTypeCoercionDuplicateFieldsAndOversizedInput() throws {
    let form = ContactForm.decode(from: try .json(Array(#"{"name":"Robin","age":"24"}"#.utf8)))
    #expect(form.validationErrors.count == 1)
    for body in ["name=one&name=two", "name=%FF", "name=%xx", "=unnamed"] {
      #expect(throws: FieldValidationError.self) { try FormValues.urlEncoded(Array(body.utf8)) }
    }
    #expect(throws: FieldValidationError.self) {
      try FormValues.urlEncoded([1, 2], maximumBytes: 1)
    }
    #expect(ContactForm.decode(from: FormValues([:])).validationErrors == [.missing("name")])
  }
}

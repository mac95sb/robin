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
  @Test func customizedControlKeepsItsLabelAndValidationFeedback() throws {
    let form = ContactForm.decode(from: try .urlEncoded(Array("name=x".utf8)))
    let html = try HTMLRenderer.render(
      form.$name.input(id: "custom-name") { control in
        Stack(id: "control-wrapper") { control }
      })
    #expect(html.contains("for=\"custom-name\""))
    #expect(html.contains("id=\"control-wrapper\""))
    #expect(html.contains("id=\"custom-name\""))
    #expect(html.contains("aria-describedby=\"custom-name-error\""))
    #expect(html.contains("id=\"custom-name-error\""))
    #expect(html.contains("aria-invalid=\"true\""))
  }

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

@Test func multilineFieldsPreserveContentAndNativeConstraints() throws {
  let field = Field(wrappedValue: "First line\n<second>", "note", required: true, maximumLength: 40)
  let content = field.input(id: "note", multiline: true) { $0 }
  let html = try HTMLRenderer.render(.fragment(content.nodes))
  #expect(html.contains("<textarea"))
  #expect(html.contains("required"))
  #expect(html.contains("maxlength=\"40\""))
  #expect(html.contains("First line\n&lt;second&gt;</textarea>"))
}

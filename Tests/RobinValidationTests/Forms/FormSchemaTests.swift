import Foundation
import Testing

@testable import RobinValidation

@Suite("Form schema, field wrapper and macro-generated names")
struct FormSchemaTests {
  @Test func fieldWrapperAndMacroProduceStableProjection() {
    struct FormState {
      @Field("email") var email = "hello@example.com"
    }
    let state = FormState()
    #expect(state.$email.name == "email")
    #expect(#generatedFieldName("email") == "form.email")
    #expect(#generatedFieldName("displayName") == "form.displayName")
  }

  @Test func oneSchemaDecodesHTMLAndAPIWithCSRFAndValidation() throws {
    let html = try FormDecoder.decodeHTMLForm(
      "email=hello%40example.com&displayName=Robin+User",
      csrfToken: "token",
      expectedCSRFToken: "token"
    )
    let api = try FormDecoder.decodeJSON(
      Data(#"{"email":"hello@example.com","displayName":"Robin User"}"#.utf8)
    )

    #expect(html == api)
    #expect(throws: FieldValidationError.invalidCSRF) {
      try FormDecoder.decodeHTMLForm(
        "",
        csrfToken: "wrong",
        expectedCSRFToken: "token"
      )
    }
  }

  @Test func noRuntimeFallbackIsNativeAccessibleHTML() {
    let html = FormDecoder.renderFallbackHTML(action: "/subscribe", csrfToken: "token")

    #expect(
      html
        == #"<form action="/subscribe" method="post"><input name="csrf" type="hidden" value="token"><label for="email">Email</label><input id="email" name="email" required type="email"><button type="submit">Submit</button></form>"#
    )
  }
}

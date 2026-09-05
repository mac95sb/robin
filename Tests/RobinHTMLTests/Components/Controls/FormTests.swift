import RobinHTML
import Testing

@Suite("Form")
struct FormTests {
  @Test func rejectsExecutableActionsForEveryMethod() throws {
    for method in [RenderElement.Attribute.FormMethod.get, .post] {
      for value in ["javascript:alert(1)", "java\rscript:alert(1)", "mailto:user@example.com"] {
        #expect(throws: RenderDiagnostic.invalidURL(attribute: "action", value: value)) {
          try HTMLRenderer.render(Form(action: value, method: method) { "Submit" })
        }
      }
    }
    #expect(
      try HTMLRenderer.render(Form(action: "?save=true") { "Submit" }).contains(
        "action=\"?save=true\""))
  }
  @Test func formDefaultsToPostSubmission() throws {
    let form = try HTMLRenderer.render(
      Form(action: "/subscribe") { Input(name: "email", accessibilityLabel: "Email") }
    )

    #expect(
      form
        == #"<form action="/subscribe" method="post"><input aria-label="Email" name="email" type="text"></form>"#
    )
  }

  @Test func formWithoutActionSubmitsToCurrentDocument() throws {
    let form = try HTMLRenderer.render(Form(method: .get) { Text { "Search" } })

    #expect(form == #"<form method="get"><p>Search</p></form>"#)
  }
}

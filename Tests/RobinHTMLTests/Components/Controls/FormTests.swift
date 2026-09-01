import RobinHTML
import Testing

@Suite("Form")
struct FormTests {
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

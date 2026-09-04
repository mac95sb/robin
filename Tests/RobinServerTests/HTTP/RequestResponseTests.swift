import HTTPTypes
import RobinServer
import Testing

@Suite("HTTP requests and responses")
struct RequestResponseTests {
  @Test func decodesURLFormFieldsAndRedirectsAfterSubmission() {
    let request = Request(
      HTTPRequest(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/notes",
        headerFields: [.contentType: "application/x-www-form-urlencoded"]
      ),
      body: Array("content=Ship+Robin%21".utf8)
    )

    #expect(request.formValue(named: "content") == "Ship Robin!")
    #expect(request.formValue(named: "missing") == nil)

    let response = Response.redirect(to: "/")
    #expect(response.head.status == .seeOther)
    #expect(response.head.headerFields[.location] == "/")
  }
}

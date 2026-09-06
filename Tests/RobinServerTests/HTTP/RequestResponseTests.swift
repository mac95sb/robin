import HTTPTypes
import RobinBuild
import RobinServer
import Testing

@Suite("HTTP requests and responses")
struct RequestResponseTests {
  @Test func serverMetadataAcceptsLocalAssetsAndRejectsUnsafePaths() throws {
    let response = try Response.html(
      metadata: .init(
        image: .init(url: "/images/share.png", alternativeText: "Preview"),
        icons: [.init(url: "/favicon.png", mediaType: "image/png")],
        manifestURL: "/site.webmanifest")
    ) { "Hello" }
    let html = String(decoding: response.body.bufferedBytes ?? [], as: UTF8.self)
    #expect(html.contains("href=\"/favicon.png\""))
    #expect(html.contains("href=\"/site.webmanifest\""))
    #expect(html.contains("content=\"/images/share.png\""))
    for path in ["//other.example/icon.png", "/../icon.png", "/images/../icon.png"] {
      #expect(throws: BuildError.self) {
        try Response.html(metadata: .init(icons: [.init(url: path)])) { "Hello" }
      }
    }
  }

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

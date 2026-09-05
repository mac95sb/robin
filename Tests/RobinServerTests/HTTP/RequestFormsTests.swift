import RobinForms
import RobinServer
import Testing

@FormModel
private struct UploadForm {
  @Field("title", required: true) var title = ""
  @Field("file", required: true) var file = FileField(filename: "", mediaType: "", bytes: [])
}

@Suite struct RequestFormsTests {
  @Test func decodesBoundedMultipartUploads() throws {
    let bytes = Array(
      ("--test\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\nRobin\r\n"
        + "--test\r\nContent-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\r\n"
        + "Content-Type: text/plain\r\n\r\nhello\r\n--test--\r\n").utf8)
    let request = Request(
      .init(
        method: .post, scheme: nil, authority: nil, path: "/upload",
        headerFields: [.contentType: "multipart/form-data; boundary=test"]), body: bytes)
    let form = try request.form(UploadForm.self).validated()
    #expect(form.title == "Robin")
    #expect(form.file.bytes == Array("hello".utf8))
    #expect(form.file.filename == "test.txt")
    #expect(throws: FieldValidationError.self) {
      try request.form(UploadForm.self, maximumBytes: 10)
    }
    #expect(throws: MultipartError.self) { try request.form(UploadForm.self, maximumFields: 1) }
  }
}

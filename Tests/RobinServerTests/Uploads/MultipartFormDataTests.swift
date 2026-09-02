import HTTPTypes
import Testing

@testable import RobinServer

@Suite("Multipart form uploads")
struct MultipartFormDataTests {
  @Test func parsesFieldsAndPreservesBinaryFileBytes() throws {
    let boundary = "robin-boundary"
    var body = Array(
      "--\(boundary)\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\nRobin"
        .utf8
    )
    body += Array(
      "\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"bird.bin\"\r\nContent-Type: application/octet-stream\r\n\r\n"
        .utf8
    )
    body += [0, 255, 13, 10]
    body += Array("\r\n--\(boundary)--\r\n".utf8)
    let request = Request(
      HTTPRequest(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/upload",
        headerFields: [.contentType: "multipart/form-data; boundary=\(boundary)"]
      ),
      body: body
    )

    let parts = try MultipartFormData.parse(request)

    #expect(parts.map(\.name) == ["title", "file"])
    #expect(parts[0].body == Array("Robin".utf8))
    #expect(parts[1].filename == "bird.bin")
    #expect(parts[1].body == [0, 255, 13, 10])
  }
}

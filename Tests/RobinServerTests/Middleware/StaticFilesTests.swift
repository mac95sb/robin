import Foundation
import HTTPTypes
import Testing

@testable import RobinServer

@Suite("Static files")
struct StaticFilesTests {
  @Test func servesContainedFilesAndRejectsTraversal() async throws {
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let root = temporary.appendingPathComponent("public", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporary) }
    try Data("hello".utf8).write(to: root.appendingPathComponent("hello.txt"))
    let secret = temporary.appendingPathComponent("secret")
    try Data("secret".utf8).write(to: secret)
    try FileManager.default.createSymbolicLink(
      at: root.appendingPathComponent("escape"),
      withDestinationURL: secret
    )
    let responder = try ApplicationResponder(
      routes: [],
      middleware: [.staticFiles(root: root)],
      transportCapabilities: .persistent
    )

    let served = await responder.respond(
      to: Request(HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/hello.txt"))
    )
    let traversal = await responder.respond(
      to: Request(HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/../secret"))
    )
    let symlink = await responder.respond(
      to: Request(HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/escape"))
    )

    guard case .file(let file) = served.body else {
      Issue.record("Expected a streamed file response")
      return
    }
    #expect(try String(contentsOf: file, encoding: .utf8) == "hello")
    #expect(traversal.head.status == .forbidden)
    #expect(symlink.head.status == .forbidden)
  }
}

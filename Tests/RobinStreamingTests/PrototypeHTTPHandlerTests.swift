import NIOCore
import NIOEmbedded
import NIOHTTP1
import RobinRendering
import RobinRoutingValidation
import Testing

@testable import RobinStreaming

@Suite("NIO request lifecycle")
struct PrototypeHTTPHandlerTests {
  private func router() -> TypedRouter {
    TypedRouter(routes: [
      TypedRoute(method: .GET, segments: [.literal("users"), .parameter("id")]) { parameters in
        .element(ElementNode(.p) { "User \(parameters["id"] ?? "missing")" })
      }
    ])
  }

  @Test func requestPipelineRoutesAndStreamsMultipleBodyChunks() throws {
    let channel = EmbeddedChannel(handler: PrototypeHTTPHandler(router: router()))
    defer { _ = try? channel.finish() }
    try channel.writeInbound(
      HTTPServerRequestPart.head(.init(version: .http1_1, method: .GET, uri: "/users/a%20b"))
    )

    let readHead: HTTPServerResponsePart? = try channel.readOutbound()
    let head = try #require(readHead)
    guard case .head(let response) = head else {
      Issue.record("Expected response head")
      return
    }
    #expect(response.status == .ok)

    var body = ""
    var bodyParts = 0
    while let part = try channel.readOutbound(as: HTTPServerResponsePart.self) {
      switch part {
      case .body(let data):
        bodyParts += 1
        guard case .byteBuffer(var bytes) = data else {
          Issue.record("Expected byte-buffer body")
          continue
        }
        body += bytes.readString(length: bytes.readableBytes) ?? ""
      case .end:
        #expect(body == "<p>User a b</p>")
        #expect(bodyParts >= 1)
        return
      case .head:
        Issue.record("Unexpected second response head")
      }
    }
    Issue.record("Response did not terminate")
  }

  @Test func missingRouteUsesTypedNotFoundLifecycle() throws {
    let channel = EmbeddedChannel(handler: PrototypeHTTPHandler(router: router()))
    defer { _ = try? channel.finish() }
    try channel.writeInbound(
      HTTPServerRequestPart.head(.init(version: .http1_1, method: .GET, uri: "/missing"))
    )

    let readPart: HTTPServerResponsePart? = try channel.readOutbound()
    let part = try #require(readPart)
    guard case .head(let response) = part else {
      Issue.record("Expected response head")
      return
    }
    #expect(response.status == .notFound)

    var body = ""
    var didEnd = false
    while let responsePart = try channel.readOutbound(as: HTTPServerResponsePart.self) {
      switch responsePart {
      case .body(let data):
        guard case .byteBuffer(var bytes) = data else {
          Issue.record("Expected byte-buffer body")
          continue
        }
        body += bytes.readString(length: bytes.readableBytes) ?? ""
      case .end:
        didEnd = true
      case .head:
        Issue.record("Unexpected second response head")
      }
    }
    #expect(body == "Not found")
    #expect(didEnd)
  }
}

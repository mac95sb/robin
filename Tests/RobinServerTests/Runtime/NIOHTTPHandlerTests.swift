import NIOCore
import NIOEmbedded
import NIOHTTP1
import Testing

@testable import RobinServer

@Suite("NIO HTTP adapter")
struct NIOHTTPHandlerTests {
  @Test func rejectsBodiesBeforeTheyReachTheApplicationResponder() throws {
    let responder = try ApplicationResponder(routes: [], transportCapabilities: .persistent)
    let channel = EmbeddedChannel(
      handler: NIOHTTPHandler(responder: responder, maximumBodyBytes: 2)
    )
    defer { _ = try? channel.finish() }
    try channel.writeInbound(
      HTTPServerRequestPart.head(.init(version: .http1_1, method: .POST, uri: "/"))
    )
    try channel.writeInbound(
      HTTPServerRequestPart.body(ByteBuffer(bytes: [1, 2, 3]))
    )
    try channel.writeInbound(HTTPServerRequestPart.end(nil))

    channel.embeddedEventLoop.run()
    let readPart: HTTPServerResponsePart? = try channel.readOutbound()
    let part = try #require(readPart)
    guard case .head(let head) = part else {
      Issue.record("Expected a response head")
      return
    }
    let status = head.status
    #expect(status == .payloadTooLarge)
  }
}

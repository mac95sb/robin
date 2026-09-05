import NIOCore
import NIOEmbedded
import NIOHTTP1
import Testing

@testable import RobinServer

@Suite("NIO HTTP adapter")
struct NIOHTTPHandlerTests {
  @Test func connectionsFromOneIPShareTheRateLimit() async throws {
    let responder = try ApplicationResponder(
      routes: [],
      middleware: [
        .security(.init(requestsPerMinute: 1)),
        .init { _, context, _ in .text(context.clientAddress ?? "missing") },
      ], transportCapabilities: .persistent)
    for (port, status) in [(20_001, 200), (20_002, 429)] {
      let channel = await NIOAsyncTestingChannel(
        handler: NIOHTTPHandler(responder: responder, maximumBodyBytes: 100))
      try await channel.connect(to: SocketAddress(ipAddress: "127.0.0.1", port: port))
      try await channel.writeInbound(
        HTTPServerRequestPart.head(.init(version: .http1_1, method: .GET, uri: "/")))
      try await channel.writeInbound(HTTPServerRequestPart.end(nil))
      let part: HTTPServerResponsePart = try await channel.waitForOutboundWrite()
      guard case .head(let head) = part else {
        Issue.record("Expected response head")
        return
      }
      #expect(head.status.code == status)
      if status == 200 {
        let body: HTTPServerResponsePart = try await channel.waitForOutboundWrite()
        guard case .body(.byteBuffer(let bytes)) = body else {
          Issue.record("Expected response body")
          return
        }
        #expect(String(buffer: bytes) == "127.0.0.1")
      }
      _ = try await channel.finish(acceptAlreadyClosed: true)
    }
  }
  @Test func rejectsBodiesBeforeTheyReachTheApplicationResponder() async throws {
    let responder = try ApplicationResponder(routes: [], transportCapabilities: .persistent)
    let channel = await NIOAsyncTestingChannel(
      handler: NIOHTTPHandler(responder: responder, maximumBodyBytes: 2)
    )
    try await channel.writeInbound(
      HTTPServerRequestPart.head(.init(version: .http1_1, method: .POST, uri: "/"))
    )
    try await channel.writeInbound(
      HTTPServerRequestPart.body(ByteBuffer(bytes: [1, 2, 3]))
    )
    try await channel.writeInbound(HTTPServerRequestPart.end(nil))

    let readPart: HTTPServerResponsePart? = try await channel.waitForOutboundWrite()
    _ = try await channel.finish(acceptAlreadyClosed: true)
    let part = try #require(readPart)
    guard case .head(let head) = part else {
      Issue.record("Expected a response head")
      return
    }
    let status = head.status
    #expect(status == .payloadTooLarge)
  }

  @Test func closesConnectionsThatExceedThePipelineQueueBound() async throws {
    let responder = try ApplicationResponder(
      routes: [],
      middleware: [
        .init { request, context, next in
          try await Task.sleep(for: .seconds(60))
          return try await next.respond(to: request, context: context)
        }
      ],
      transportCapabilities: .persistent)
    let channel = await NIOAsyncTestingChannel(
      handler: NIOHTTPHandler(responder: responder, maximumBodyBytes: 2)
    )
    try await channel.connect(to: SocketAddress(ipAddress: "127.0.0.1", port: 8080))
    #expect(channel.isActive)

    for number in 0...(NIOHTTPHandler.maximumPendingRequests + 1) {
      try await channel.writeInbound(
        HTTPServerRequestPart.head(
          .init(version: .http1_1, method: .GET, uri: "/\(number)")))
      try await channel.writeInbound(HTTPServerRequestPart.end(nil))
    }
    #expect(!channel.isActive)
    _ = try await channel.finish(acceptAlreadyClosed: true)
  }
}

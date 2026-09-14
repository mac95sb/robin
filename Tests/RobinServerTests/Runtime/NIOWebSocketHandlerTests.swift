import Foundation
import NIOCore
import NIOEmbedded
import NIOWebSocket
import RobinCore
import RobinHTML
import RobinRouting
import Testing

@testable import RobinServer

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

// FoundationNetworking's libcurl does not implement WebSocket clients.
#if !canImport(FoundationNetworking)
  @Test func upgradedConnectionExchangesMessagesAndLeavesHTTPAvailable() async throws {
    let server = try await ServerRuntime.start(SocketApplication(), port: 0)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 5
    configuration.timeoutIntervalForResource = 10
    let client = URLSession(configuration: configuration)
    defer { client.invalidateAndCancel() }
    do {
      let address = try #require(await server.localAddress)
      let socket = client.webSocketTask(
        with: URL(string: "ws://127.0.0.1:\(address.port)/api/socket")!)
      socket.resume()
      for text in ["First message", "A second message 👋"] {
        try await socket.send(.string(text))
        let received = try await socket.receive()
        guard case .string(let echoed) = received else {
          Issue.record("Expected an echoed text message")
          break
        }
        #expect(echoed == text)
      }
      let bytes = Data([0, 1, 255])
      try await socket.send(.data(bytes))
      let received = try await socket.receive()
      if case .data(let echoed) = received {
        #expect(echoed == bytes)
      } else {
        Issue.record("Expected an echoed binary message")
      }
      socket.cancel(with: .normalClosure, reason: nil)

      let (body, response) = try await client.data(
        from: URL(string: "http://127.0.0.1:\(address.port)/")!)
      #expect((response as? HTTPURLResponse)?.statusCode == 200)
      #expect(String(decoding: body, as: UTF8.self).contains("Still running"))
      try await server.shutdown()
    } catch {
      try? await server.shutdown()
      throw error
    }
  }
#endif

private struct SocketApplication: App {
  @PagesBuilder var pages: PageList { SocketHomePage() }
  @RoutesBuilder var routes: RouteList { EchoSocket() }
}

private struct SocketHomePage: Page {
  let path = "/"
  var body: ComponentContent { Text { "Still running" } }
}

private struct EchoSocket: APIRoute, ServerRoute {
  let method = HTTPMethod.get
  let version: Version? = nil
  let pattern = RoutePattern([.literal("socket")])
  let requiredCapabilities: TransportCapabilities = [.webSockets]

  func respond(to request: Request, context _: RequestContext, api: APIConfiguration) -> Response? {
    guard request.path == "\(api.root.value)/socket" else { return nil }
    return .webSocket(
      WebSocketSession { connection, messages in
        for await message in messages { try await connection.send(message) }
      })
  }
}

@Test func websocketIngressClosesWhenItsBoundedBufferFills() async throws {
  let session = WebSocketSession { _, _ in
    try await Task.sleep(for: .seconds(10))
  }
  let channel = await NIOAsyncTestingChannel(handler: NIOWebSocketHandler(session: session))
  try await channel.connect(to: SocketAddress(ipAddress: "127.0.0.1", port: 8080))
  #expect(channel.isActive)

  for number in 0...NIOWebSocketHandler.maximumPendingMessages {
    try await channel.writeInbound(
      WebSocketFrame(fin: true, opcode: .text, data: ByteBuffer(string: "\(number)")))
  }
  #expect(!channel.isActive)
  _ = try await channel.finish(acceptAlreadyClosed: true)
}

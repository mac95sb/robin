import HTTPTypes
import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle
import Testing

@testable import RobinServer

@Suite("WebSocket browser module")
struct WebSocketClientModuleTests {
  private struct Home: Page {
    let path = "/"
    var body: ComponentContent { Text { "Chat" }.margin(.sm) }
  }

  private struct TestApplication: App {
    var metadata: Metadata { Metadata() }
    var pages: some Pages { Home() }
  }

  @Test func validatesBindsAndServesItsTypedAsset() async throws {
    #expect(throws: WebSocketClientModuleError.invalidConfiguration) {
      try WebSocketClientModule(
        path: "/../chat", formID: "form", inputID: "input", messagesID: "messages",
        statusID: "status")
    }
    let module = try WebSocketClientModule(
      path: "/api/v1/chat", formID: "form", inputID: "input", messagesID: "messages",
      statusID: "status")
    let asset = try module.asset()
    #expect(
      asset.scriptOrigin == .robinDirectCapability(.stream, selectedBy: "WebSocketClientModule"))
    let responder = try ApplicationResponder(
      TestApplication(),
      middleware: [.clientAssets([asset])],
      transportCapabilities: .persistent)

    let page = await responder.respond(
      to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/")))
    #expect(
      String(decoding: page.body.bufferedBytes ?? [], as: UTF8.self)
        .contains(#"<script type="module" src="/robin/websocket.js"></script>"#))
    #expect(String(decoding: page.body.bufferedBytes ?? [], as: UTF8.self).contains("<style"))
    #expect(
      String(decoding: page.body.bufferedBytes ?? [], as: UTF8.self).hasSuffix(
        "</script></body></html>"))

    let script = await responder.respond(
      to: Request(.init(method: .get, scheme: nil, authority: nil, path: asset.reference)))
    #expect(script.head.headerFields[.contentType] == "text/javascript")
    #expect(
      String(decoding: script.body.bufferedBytes ?? [], as: UTF8.self).contains("new WebSocket"))
  }
}

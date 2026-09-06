import Foundation
import HTTPTypes
import RobinCore
import RobinHTML
import RobinRuntime
import RobinServer
import Testing

@Test func serverPagesAutomaticallyDeliverClientState() async throws {
  struct StatefulPage: Page {
    let path = "/"
    @State var count = 0
    var body: ComponentContent {
      Text { $count }
      Button(action: #action { count += 1 }) { "+" }
    }
  }
  struct Site: App { var pages: some Pages { StatefulPage() } }
  let responder = try ApplicationResponder(Site(), transportCapabilities: [])
  let response = await responder.respond(
    to: .init(HTTPRequest(method: .get, scheme: "http", authority: "localhost", path: "/")))
  let html = String(decoding: response.body.bufferedBytes ?? [], as: UTF8.self)
  #expect(html.contains("src=\"/robin/state.js\""))
  let script = await responder.respond(
    to: .init(
      HTTPRequest(method: .get, scheme: "http", authority: "localhost", path: "/robin/state.js")))
  #expect(script.head.status.code == 200)
  #expect(String(decoding: script.body.bufferedBytes ?? [], as: UTF8.self).contains("robin.state"))
}

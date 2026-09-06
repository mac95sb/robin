import Foundation
import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func pageAndControllerRespond() async throws {
  let client = try RouteTestClient(Site())
  let page = await client.response(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/")))
  #expect(page.head.status == .ok)
  #expect(String(decoding: page.body.bufferedBytes ?? [], as: UTF8.self).contains("Hello, world!"))

  let response = await client.response(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/v1/message")))
  #expect(response.head.status == .ok)
  let message = try JSONDecoder().decode(
    Message.self, from: Data(response.body.bufferedBytes ?? []))
  #expect(message.text == "Hello, world!")
}

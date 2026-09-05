import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func healthRouteRespondsSuccessfully() async throws {
  let client = try RouteTestClient(Site())
  let response = await client.response(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/system/health")))
  #expect(response.head.status == .ok)
}

@Test func typedVersionedTodoRouteRespondsSuccessfully() async throws {
  let client = try RouteTestClient(Site())
  let response = await client.response(
    to: Request(
      .init(method: .get, scheme: nil, authority: nil, path: "/api/v1/catalog/todos/1")))
  #expect(response.head.status == .ok)
}

@Test func todoCreationValidatesJSON() async throws {
  let client = try RouteTestClient(Site())
  let created = await client.response(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/catalog/todos",
        headerFields: [.contentType: "application/json"]),
      body: Array(#"{"title":"Write tests"}"#.utf8)))
  #expect(created.head.status == .ok)

  let rejected = await client.response(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/catalog/todos",
        headerFields: [.contentType: "application/json", .accept: "application/json"]),
      body: Array(#"{"title":"  "}"#.utf8)))
  #expect(rejected.head.status == .badRequest)

  let oversized = await client.response(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/catalog/todos",
        headerFields: [.contentType: "application/json"]),
      body: Array(#"{"title":"\#(String(repeating: "a", count: 201))"}"#.utf8)))
  #expect(oversized.head.status == .badRequest)
}

@Test func todoRetentionIsBounded() {
  let todos = TodoService()
  for number in 0...TodoService.maximumTodos {
    _ = todos.create(title: "Todo \(number)")
  }
  #expect(todos.all().count == TodoService.maximumTodos)
}

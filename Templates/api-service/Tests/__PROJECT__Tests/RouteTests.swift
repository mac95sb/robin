import Foundation
import RobinCore
import RobinHTML
import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

private struct TestSite: App {
  @RoutesBuilder var routes: RouteList {
    HealthController()
    TodoController()
  }
}

@Test func healthRouteRespondsSuccessfully() async throws {
  let client = try RouteTestClient(TestSite())
  let response = await client.response(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/system/health")))
  #expect(response.head.status == .ok)
}

@Test func todoRouteRespondsSuccessfully() async throws {
  let site = TestSite()
  let client = try RouteTestClient(site)
  let created = await client.response(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/catalog/todos",
        headerFields: [.contentType: "application/json"]),
      body: Array(#"{"title":"Write tests"}"#.utf8)))
  let todo = try JSONDecoder().decode(
    Todo.self, from: Data(try #require(created.body.bufferedBytes)))
  let response = await client.response(
    to: Request(
      .init(method: .get, scheme: nil, authority: nil, path: "/api/v1/catalog/todos/\(todo.id)")))
  #expect(response.head.status == .ok)
}

@Test func todoCreationValidatesJSON() async throws {
  let client = try RouteTestClient(TestSite())
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

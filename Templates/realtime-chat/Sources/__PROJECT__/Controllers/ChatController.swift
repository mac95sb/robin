import RobinHTML
import RobinRouting
import RobinServer

struct ChatController: Controller {
  let messages: MessageStore

  @RoutesBuilder var body: RouteList {
    History(messages: messages)
    Socket(messages: messages)
  }

  private struct History: Endpoint {
    let route = "messages"
    let messages: MessageStore

    func handle(_: Void, request _: EmptyRequest, context: RequestContext) async throws
      -> [ChatMessage]
    {
      guard context.principal != nil else {
        throw ServerError(.unauthorized, "Sign in to read messages.")
      }
      return try await messages.all()
    }
  }

  private struct Socket: APIRoute, ServerRoute {
    let messages: MessageStore
    let method = HTTPMethod.get
    let version: Version? = .default
    let metadata = RouteMetadata(operationID: "chat.connect", summary: "Joins the chat.")
    let pattern = RoutePattern([.literal("chat")])
    let requiredCapabilities: TransportCapabilities = [.webSockets, .processLocalState]

    func respond(
      to request: Request,
      context: RequestContext,
      api: APIConfiguration
    ) throws -> Response? {
      guard request.method.rawValue.lowercased() == method.rawValue,
        request.path == "\(api.root.value)/v\(Version.default.number)/chat"
      else { return nil }
      guard let principal = context.principal else {
        throw ServerError(.unauthorized, "Sign in to join the chat.")
      }
      return .webSocket(
        WebSocketSession { connection, incoming in
          let (subscription, outgoing) = await messages.subscribe()
          do {
            try await withThrowingTaskGroup(of: Void.self) { group in
              group.addTask {
                for await message in incoming {
                  guard case .text(let text) = message else { continue }
                  _ = try await messages.append(text, authorID: principal.id)
                }
              }
              group.addTask {
                for await message in outgoing {
                  try await connection.send(.text("\(message.authorID): \(message.text)"))
                }
              }
              _ = try await group.next()
              group.cancelAll()
            }
            await messages.unsubscribe(subscription)
            try await connection.close()
          } catch {
            await messages.unsubscribe(subscription)
            try? await connection.close()
            throw error
          }
        })
    }
  }
}

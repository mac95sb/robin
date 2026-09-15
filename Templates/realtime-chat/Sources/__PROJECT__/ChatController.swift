import Foundation
import RobinCore
import RobinServer

/// Serves authenticated message history and realtime connections.
struct ChatController: Controller {
  let messages: MessageStore

  @RoutesBuilder var body: RouteList {
    RouteGroup("messages") { GET(use: history) }
    RouteGroup("chat") {
      WebSocketRoute(requiredCapabilities: [.processLocalState], use: socket)
    }
  }

  private func history(_: Void, _ context: RequestContext) async throws -> [ChatMessage] {
    guard context.principal != nil else {
      throw ServerError(.unauthorized, "Sign in to read messages.")
    }
    return try await messages.all()
  }

  private func socket(_ context: RequestContext) throws -> WebSocketSession {
    guard let principal = context.principal else {
      throw ServerError(.unauthorized, "Sign in to join the chat.")
    }
    return WebSocketSession { connection, incoming in
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
              let payload = WebSocketClientModule.Message(
                text: "\(message.authorID): \(message.text)",
                title: message.sentAt.ISO8601Format()
              )
              let data = try JSONEncoder().encode(payload)
              try await connection.send(.text(String(decoding: data, as: UTF8.self)))
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
    }
  }
}

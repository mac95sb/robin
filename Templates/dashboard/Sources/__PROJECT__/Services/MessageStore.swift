import Foundation
import RobinCore
import RobinData

/// Stores messages for the current request.
struct MessageListKey: ConfigurationKey {
  static let defaultValue: [ChatMessage] = []
}

/// Persists the shared message history and publishes realtime updates.
actor MessageStore {
  static let maximumMessageBytes = 4_096
  static let maximumMessages = 100
  private let storage: any KeyValueStore
  private var subscribers: [UUID: AsyncStream<ChatMessage>.Continuation] = [:]

  init(_ storage: any KeyValueStore) { self.storage = storage }

  func subscribe() -> (UUID, AsyncStream<ChatMessage>) {
    let id = UUID()
    let (stream, continuation) = AsyncStream.makeStream(
      of: ChatMessage.self,
      bufferingPolicy: .bufferingOldest(32)
    )
    subscribers[id] = continuation
    return (id, stream)
  }

  func unsubscribe(_ id: UUID) { subscribers.removeValue(forKey: id)?.finish() }

  func all(at now: Date = Date()) async throws -> [ChatMessage] {
    guard let data = try await storage.value(forKey: "history", namespace: "chat", at: now)
    else { return [] }
    return Array(
      try JSONDecoder().decode([ChatMessage].self, from: data).suffix(Self.maximumMessages)
    )
  }

  func append(_ text: String, authorID: String, at now: Date = Date()) async throws
    -> ChatMessage
  {
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { throw MessageStoreError.emptyMessage }
    guard text.utf8.count <= Self.maximumMessageBytes else {
      throw MessageStoreError.messageTooLarge
    }
    let message = ChatMessage(id: UUID(), authorID: authorID, text: text, sentAt: now)
    while true {
      try Task.checkCancellation()
      let previous = try await storage.value(forKey: "history", namespace: "chat", at: now)
      var messages =
        try previous.map { try JSONDecoder().decode([ChatMessage].self, from: $0) } ?? []
      messages.append(message)
      if try await storage.put(
        JSONEncoder().encode(Array(messages.suffix(Self.maximumMessages))),
        forKey: "history",
        namespace: "chat",
        expiresAt: nil,
        condition: previous.map { .ifEqual($0) } ?? .ifAbsent
      ) {
        for (id, subscriber) in subscribers {
          if case .dropped = subscriber.yield(message) { unsubscribe(id) }
        }
        return message
      }
    }
  }
}

/// Describes invalid chat message input.
enum MessageStoreError: Error { case emptyMessage, messageTooLarge }

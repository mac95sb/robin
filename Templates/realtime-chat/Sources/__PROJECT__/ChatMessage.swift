import Foundation

/// A message in the shared conversation.
struct ChatMessage: Codable, Equatable, Sendable {
  let id: UUID
  let authorID: String
  let text: String
  let sentAt: Date
}

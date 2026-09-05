import Foundation

struct ChatMessage: Codable, Equatable, Sendable {
  let id: UUID
  let authorID: String
  let text: String
  let sentAt: Date
}

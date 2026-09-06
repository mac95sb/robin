import Foundation

struct ChatMessage: Codable, Equatable, Sendable {
  let id: UUID
  let authorID: String
  let text: String
  let sentAt: Date

  var timestamp: String {
    sentAt.ISO8601Format().replacingOccurrences(of: "T", with: " ")
      .replacingOccurrences(of: "Z", with: " UTC")
  }
}

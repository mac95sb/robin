/// A private note owned by an authenticated person.
struct Note: Codable, Sendable {
  let id: Int
  var content: String
}

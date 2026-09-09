import Foundation
import RobinCore
import RobinData

/// Stores the current person’s username.
struct UsernameKey: ConfigurationKey {
  static let defaultValue: String? = nil
}

/// Stores display names for conversation authors.
struct AuthorNamesKey: ConfigurationKey {
  static let defaultValue: [String: String] = [:]
}

/// Persists unique display names for authenticated people.
struct UsernameStore: Sendable {
  let storage: any KeyValueStore

  func all() async throws -> [String: String] {
    guard let data = try await storage.value(forKey: "usernames", namespace: "chat", at: Date())
    else { return [:] }
    return try JSONDecoder().decode([String: String].self, from: data)
  }

  func set(_ proposed: String, for accountID: String) async throws {
    let username = proposed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard (3...24).contains(username.utf8.count),
      username.utf8.allSatisfy({ (97...122).contains($0) || (48...57).contains($0) || $0 == 95 })
    else { throw UsernameError.invalid }
    // ponytail: one atomic registry costs O(accounts); use a unique database index for a large community.
    while true {
      try Task.checkCancellation()
      let previous = try await storage.value(forKey: "usernames", namespace: "chat", at: Date())
      var names =
        try previous.map { try JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
      guard !names.contains(where: { $0.key != accountID && $0.value == username })
      else { throw UsernameError.taken }
      names[accountID] = username
      if try await storage.put(
        JSONEncoder().encode(names),
        forKey: "usernames",
        namespace: "chat",
        expiresAt: nil,
        condition: previous.map { .ifEqual($0) } ?? .ifAbsent
      ) {
        return
      }
    }
  }
}

/// Describes an invalid or unavailable username.
enum UsernameError: Error {
  case invalid, taken

  var message: String {
    switch self {
    case .invalid: "Use 3–24 letters, numbers, or underscores."
    case .taken: "That username is already taken. Choose another."
    }
  }
}

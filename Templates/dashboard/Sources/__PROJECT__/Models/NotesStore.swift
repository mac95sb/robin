import Foundation
import RobinCore
import RobinData

enum NoteListKey: ConfigurationKey {
  static let defaultValue: [Note] = []
}

actor NotesStore {
  private let storage: any KeyValueStore

  init(_ storage: any KeyValueStore) { self.storage = storage }

  func all(ownerID: String, at now: Date = Date()) async throws -> [Note] {
    guard
      let data = try await storage.value(
        forKey: ownerID, namespace: "dashboard.notes", at: now)
    else { return [Note(id: 1, content: "Build something useful with Robin.")] }
    return try JSONDecoder().decode([Note].self, from: data)
  }

  func create(_ content: String, ownerID: String, at now: Date = Date()) async throws {
    let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !content.isEmpty else { return }
    try await modify(ownerID: ownerID, at: now) { notes in
      notes.append(Note(id: (notes.map(\.id).max() ?? 0) + 1, content: content))
    }
  }

  func update(_ id: Int, content: String, ownerID: String, at now: Date = Date()) async throws {
    let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !content.isEmpty else { return }
    try await modify(ownerID: ownerID, at: now) { notes in
      guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
      notes[index].content = content
    }
  }

  func delete(_ id: Int, ownerID: String, at now: Date = Date()) async throws {
    try await modify(ownerID: ownerID, at: now) { notes in
      notes.removeAll { $0.id == id }
    }
  }

  private func modify(ownerID: String, at now: Date, _ change: (inout [Note]) -> Void) async throws
  {
    // ponytail: one encoded list suits a starter; use a Repository when note volume needs queries.
    while true {
      try Task.checkCancellation()
      let previous = try await storage.value(forKey: ownerID, namespace: "dashboard.notes", at: now)
      var notes =
        try previous.map { try JSONDecoder().decode([Note].self, from: $0) }
        ?? [Note(id: 1, content: "Build something useful with Robin.")]
      change(&notes)
      if try await storage.put(
        JSONEncoder().encode(notes), forKey: ownerID, namespace: "dashboard.notes", expiresAt: nil,
        condition: previous.map { .ifEqual($0) } ?? .ifAbsent)
      {
        return
      }
    }
  }
}

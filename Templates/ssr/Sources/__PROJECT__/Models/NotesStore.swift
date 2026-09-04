import Foundation

// ponytail: Process-local demo storage; use request-scoped RobinData when SSR pages receive services.
final class NotesStore: @unchecked Sendable {
  private let lock = NSLock()
  private var notes = [Note(id: 1, content: "Build something useful with Robin.")]

  func all() -> [Note] { withLock { notes } }

  func create(_ content: String) {
    let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !content.isEmpty else { return }
    withLock {
      notes.append(Note(id: (notes.map(\.id).max() ?? 0) + 1, content: content))
    }
  }

  func update(_ id: Int, content: String) {
    let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !content.isEmpty else { return }
    withLock {
      guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
      notes[index].content = content
    }
  }

  func delete(_ id: Int) {
    withLock { notes.removeAll { $0.id == id } }
  }

  private func withLock<Result>(_ operation: () -> Result) -> Result {
    lock.lock()
    defer { lock.unlock() }
    return operation()
  }
}

import Foundation
import RobinData
import Testing

@testable import __PROJECT__

@Test func notesSurviveDatabaseReopen() async throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
  defer { try? FileManager.default.removeItem(at: directory) }
  let storage = SQLiteDatabase.Storage.file(
    path: directory.appendingPathComponent("db.sqlite").path
  )

  let first = try await DashboardServices(storage: storage)
  try await NotesStore(first.storage).create("Persistent note", ownerID: "demo")
  try await first.shutdown()

  let second = try await DashboardServices(storage: storage)
  #expect(
    try await NotesStore(second.storage).all(ownerID: "demo")
      .contains {
        $0.content == "Persistent note"
      }
  )
  try await second.shutdown()
}

@Test func concurrentNotesAreNotLost() async throws {
  let services = try await DashboardServices()
  let notes = NotesStore(services.storage)
  try await withThrowingTaskGroup(of: Void.self) { group in
    for number in 0..<20 {
      group.addTask { try await notes.create("Note \(number)", ownerID: "demo") }
    }
    try await group.waitForAll()
  }
  #expect(try await notes.all(ownerID: "demo").count == 21)
  try await services.shutdown()
}

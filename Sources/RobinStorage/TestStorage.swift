import Foundation

/// An isolated temporary local store for tests.
public struct TestStorage: Sendable {
  /// Store under test.
  public let storage: any Storage
  private let root: URL

  /// Creates an isolated local store.
  public static func local() throws -> Self {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      "robin-storage-\(UUID().uuidString)", isDirectory: true)
    return try Self(storage: LocalStorage(root: root), root: root)
  }

  /// Removes all isolated test data.
  public func remove() throws {
    if FileManager.default.fileExists(atPath: root.path) {
      try FileManager.default.removeItem(at: root)
    }
  }
}

import Crypto
import Foundation
import NIOCore

/// Production local-filesystem object storage with isolated object namespaces.
public actor LocalStorage: Storage {
  private let root: URL
  private let now: @Sendable () -> Date

  /// Creates local storage under an absolute directory URL.
  public init(root: URL, now: @escaping @Sendable () -> Date = Date.init) throws {
    guard root.isFileURL, root.path.hasPrefix("/") else { throw StorageError.invalidRoot }
    self.root = root.standardizedFileURL
    self.now = now
    try FileManager.default.createDirectory(at: self.root, withIntermediateDirectories: true)
  }

  /// Streams, validates, and atomically publishes an object directory.
  public func put(_ write: StorageWrite) async throws -> StorageMetadata {
    guard write.policy.contentTypes.isEmpty || write.policy.contentTypes.contains(write.contentType)
    else { throw StorageError.unsupportedContentType(write.contentType) }
    let staging = root.appendingPathComponent(".staging-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: false)
    do {
      let bodyURL = staging.appendingPathComponent("body")
      FileManager.default.createFile(atPath: bodyURL.path, contents: nil)
      let handle = try FileHandle(forWritingTo: bodyURL)
      var hasher = SHA256()
      var size: Int64 = 0
      do {
        for try await chunk in write.body.chunks() {
          let data = Data(chunk.readableBytesView)
          size += Int64(data.count)
          guard size <= write.policy.maximumBytes else {
            throw StorageError.sizeLimitExceeded(write.policy.maximumBytes)
          }
          hasher.update(data: data)
          try handle.write(contentsOf: data)
        }
        try handle.close()
      } catch {
        try? handle.close()
        throw error
      }
      let digest = hasher.finalize()
      let digits = Array("0123456789abcdef".utf8)
      let checksum = String(
        decoding: digest.flatMap { [digits[Int($0 >> 4)], digits[Int($0 & 0x0f)]] },
        as: UTF8.self)
      if let expected = write.expectedChecksum, expected.lowercased() != checksum {
        throw StorageError.checksumMismatch(expected: expected, actual: checksum)
      }
      let metadata = StorageMetadata(
        key: write.key.object.value,
        tenantIdentity: write.key.tenantIdentity,
        contentType: write.contentType,
        size: size,
        checksum: checksum,
        createdAt: now()
      )
      try JSONEncoder.storage.encode(metadata).write(
        to: staging.appendingPathComponent("metadata.json"), options: .atomic)
      let destination = objectDirectory(write.key)
      if FileManager.default.fileExists(atPath: destination.path) {
        _ = try FileManager.default.replaceItemAt(destination, withItemAt: staging)
      } else {
        try FileManager.default.moveItem(at: staging, to: destination)
      }
      return metadata
    } catch {
      try? FileManager.default.removeItem(at: staging)
      throw error
    }
  }

  /// Opens a stored object without loading its body into memory.
  public func object(for key: ScopedObjectKey) async throws -> StoredObject? {
    let directory = objectDirectory(key)
    guard FileManager.default.fileExists(atPath: directory.path) else { return nil }
    let metadataURL = directory.appendingPathComponent("metadata.json")
    let bodyURL = directory.appendingPathComponent("body")
    guard let data = FileManager.default.contents(atPath: metadataURL.path),
      FileManager.default.fileExists(atPath: bodyURL.path)
    else { throw StorageError.corruptObject }
    let metadata = try JSONDecoder.storage.decode(StorageMetadata.self, from: data)
    guard metadata.key == key.object.value, metadata.tenantIdentity == key.tenantIdentity else {
      throw StorageError.corruptObject
    }
    return StoredObject(metadata: metadata, body: Self.fileBody(bodyURL))
  }

  /// Removes one isolated object directory.
  public func remove(_ key: ScopedObjectKey) throws -> Bool {
    let directory = objectDirectory(key)
    guard FileManager.default.fileExists(atPath: directory.path) else { return false }
    try FileManager.default.removeItem(at: directory)
    return true
  }

  /// Removes a bounded number of retained objects.
  public func removeCreated(before cutoff: Date, limit: Int) throws -> Int {
    guard limit > 0 else { throw StorageError.invalidCleanupLimit }
    let directories = try FileManager.default.contentsOfDirectory(
      at: root, includingPropertiesForKeys: nil)
    var removed = 0
    // ponytail: one flat directory keeps local cleanup bounded; shard only if measured object counts require it.
    for directory in directories.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
    where removed < limit && !directory.lastPathComponent.hasPrefix(".staging-") {
      let metadataURL = directory.appendingPathComponent("metadata.json")
      guard let data = FileManager.default.contents(atPath: metadataURL.path),
        let metadata = try? JSONDecoder.storage.decode(StorageMetadata.self, from: data),
        metadata.createdAt < cutoff
      else { continue }
      try FileManager.default.removeItem(at: directory)
      removed += 1
    }
    return removed
  }

  private func objectDirectory(_ key: ScopedObjectKey) -> URL {
    root.appendingPathComponent(key.storageIdentifier, isDirectory: true)
  }

  private static func fileBody(_ url: URL) -> StorageBody {
    StorageBody {
      AsyncThrowingStream { continuation in
        let task = Task {
          do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            while !Task.isCancelled,
              let data = try handle.read(upToCount: 64 * 1_024), !data.isEmpty
            {
              continuation.yield(ByteBuffer(bytes: data))
            }
            continuation.finish()
          } catch {
            continuation.finish(throwing: error)
          }
        }
        continuation.onTermination = { _ in task.cancel() }
      }
    }
  }
}

extension JSONEncoder {
  fileprivate static var storage: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    encoder.outputFormatting = [.sortedKeys]
    return encoder
  }
}

extension JSONDecoder {
  fileprivate static var storage: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }
}

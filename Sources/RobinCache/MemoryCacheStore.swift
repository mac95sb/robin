import Foundation

/// A bounded least-recently-used in-memory cache store.
public actor MemoryCacheStore: CacheStore {
  private struct Stored: Sendable {
    var record: CacheRecord
    var access: UInt64
  }

  private let capacity: Int
  private var records: [String: Stored] = [:]
  private var access: UInt64 = 0

  /// Creates an in-memory store with a maximum entry count.
  public init(capacity: Int) {
    precondition(capacity > 0)
    self.capacity = capacity
  }

  /// Reads a usable record and updates its recency.
  public func record(for key: String, at now: Date) -> CacheRecord? {
    guard var stored = records[key] else { return nil }
    guard stored.record.staleUntil > now else {
      records[key] = nil
      return nil
    }
    access &+= 1
    stored.access = access
    records[key] = stored
    return stored.record
  }

  /// Stores a record and evicts the least recently used entry when full.
  public func store(_ record: CacheRecord, for key: String) {
    access &+= 1
    records[key] = Stored(record: record, access: access)
    if records.count > capacity,
      let oldest = records.min(by: { $0.value.access < $1.value.access })?.key
    {
      records[oldest] = nil
    }
  }

  /// Removes one record.
  public func remove(_ key: String) { records[key] = nil }

  /// Removes entries matching any tag.
  public func invalidate(tags: Set<String>) {
    records = records.filter { $0.value.record.tags.isDisjoint(with: tags) }
  }

  /// Removes every entry.
  public func removeAll() { records.removeAll(keepingCapacity: true) }
}

import Crypto
import Foundation
import RobinCore

/// Typed encoding, tenant-aware tags, and observability over a cache provider.
public struct Cache: Sendable {
  /// Receives cache events for logs, metrics, or traces.
  public typealias Observer = @Sendable (CacheEvent) -> Void

  private let store: any CacheStore
  private let now: @Sendable () -> Date
  private let observer: Observer?

  /// Creates a typed cache facade.
  public init(
    store: any CacheStore,
    now: @escaping @Sendable () -> Date = Date.init,
    observer: Observer? = nil
  ) {
    self.store = store
    self.now = now
    self.observer = observer
  }

  /// Reads and decodes a typed value.
  public func value<Value: Codable & Sendable>(for key: CacheKey<Value>) async throws
    -> CachedValue<Value>?
  {
    let date = now()
    do {
      guard let record = try await store.record(for: key.storageKey, at: date) else {
        observer?(.miss(key.storageKey))
        return nil
      }
      let freshness: CacheFreshness = record.expiresAt > date ? .fresh : .stale
      observer?(freshness == .fresh ? .hit(key.storageKey) : .stale(key.storageKey))
      return CachedValue(
        value: try JSONDecoder().decode(Value.self, from: record.data),
        freshness: freshness,
        entityTag: record.entityTag,
        lastModified: record.lastModified
      )
    } catch {
      observer?(.failed(key.storageKey))
      throw error
    }
  }

  /// Encodes and stores a typed value.
  public func store<Value: Codable & Sendable>(
    _ value: Value,
    for key: CacheKey<Value>,
    policy: CachePolicy,
    tags: Set<CacheTag> = []
  ) async throws {
    let data = try JSONEncoder().encode(value)
    let date = now()
    let expiry = date.addingTimeInterval(policy.freshness.seconds)
    let scopedTags = Set(tags.map { $0.scoped(to: key.tenant) })
    do {
      try await store.store(
        CacheRecord(
          data: data,
          expiresAt: expiry,
          staleUntil: expiry.addingTimeInterval(policy.staleWhileRevalidate.seconds),
          entityTag: "\"\(Self.checksum(data))\"",
          lastModified: date,
          tags: scopedTags
        ),
        for: key.storageKey
      )
      observer?(.stored(key.storageKey))
    } catch {
      observer?(.failed(key.storageKey))
      throw error
    }
  }

  /// Invalidates tags within one explicit tenant scope.
  public func invalidate(_ tags: Set<CacheTag>, tenant: TenantScope<String>) async throws {
    try await store.invalidate(tags: Set(tags.map { $0.scoped(to: tenant) }))
    observer?(.invalidated(tags.count))
  }

  /// Removes one typed key.
  public func remove<Value>(_ key: CacheKey<Value>) async throws where Value: Codable & Sendable {
    try await store.remove(key.storageKey)
  }

  private static func checksum(_ data: Data) -> String {
    let digest = SHA256.hash(data: data)
    let digits = Array("0123456789abcdef".utf8)
    return String(
      decoding: digest.flatMap { [digits[Int($0 >> 4)], digits[Int($0 & 0x0f)]] },
      as: UTF8.self)
  }
}

extension CacheTag {
  fileprivate func scoped(to tenant: TenantScope<String>) -> String {
    switch tenant {
    case .none: "none:\(value)"
    case .tenant(let context): "tenant:\(context.id.utf8.count):\(context.id):\(value)"
    }
  }
}

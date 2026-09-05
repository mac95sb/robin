import Foundation
import RobinCore
import RobinStorage
import Testing

@Suite("Tenant-safe object storage")
struct StorageTests {
  @Test func streamsValidatesAndIsolatesTenants() async throws {
    let testStorage = try TestStorage.local()
    do {
      let first = try key(tenant: "first")
      let second = try key(tenant: "second")
      let policy = StoragePolicy(contentTypes: ["text/plain"], maximumBytes: 5)
      async let firstWrite = testStorage.storage.put(
        StorageWrite(
          key: first, contentType: "text/plain", policy: policy,
          body: .bytes(Data("first".utf8))))
      async let secondWrite = testStorage.storage.put(
        StorageWrite(
          key: second, contentType: "text/plain", policy: policy,
          body: .bytes(Data("other".utf8))))
      _ = try await (firstWrite, secondWrite)

      #expect(try await bytes(testStorage.storage.object(for: first)) == Data("first".utf8))
      #expect(try await bytes(testStorage.storage.object(for: second)) == Data("other".utf8))
      await #expect(throws: StorageError.sizeLimitExceeded(4)) {
        try await testStorage.storage.put(
          StorageWrite(
            key: first, contentType: "text/plain",
            policy: .init(maximumBytes: 4), body: .bytes(Data("first".utf8))))
      }
      #expect(try await bytes(testStorage.storage.object(for: first)) == Data("first".utf8))
      try testStorage.remove()
    } catch {
      try? testStorage.remove()
      throw error
    }
  }

  @Test func rejectsTraversalAndSupportsBoundedRetention() async throws {
    #expect(throws: StorageError.invalidObjectKey("../secret")) { try ObjectKey("../secret") }
    let testStorage = try TestStorage.local()
    do {
      for name in ["one", "two"] {
        let key = ScopedObjectKey(try ObjectKey(name), tenant: .none)
        _ = try await testStorage.storage.put(
          StorageWrite(
            key: key, contentType: "text/plain", policy: .init(maximumBytes: 1),
            body: .bytes(Data(name.prefix(1).utf8))))
      }
      #expect(try await testStorage.storage.removeCreated(before: .distantFuture, limit: 1) == 1)
      #expect(try await testStorage.storage.removeCreated(before: .distantFuture, limit: 1) == 1)
      try testStorage.remove()
    } catch {
      try? testStorage.remove()
      throw error
    }
  }

  @Test func signsTenantAwareS3UploadAndDownloadIntents() async throws {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let storage = S3CompatibleStorage(
      configuration: try S3Configuration(
        endpoint: #require(URL(string: "https://objects.example.com")),
        bucket: "uploads", region: "eu-west-2",
        accessKeyID: "access", secretAccessKey: "secret"),
      now: { date })
    let key = try key(tenant: "acme")
    let upload = try await storage.intent(
      for: key, operation: .upload(contentType: "image/png", maximumBytes: 1_024),
      expiresAt: date.addingTimeInterval(300))
    let download = try await storage.intent(
      for: key, operation: .download, expiresAt: date.addingTimeInterval(300))

    #expect(upload.method == "POST")
    let objectPath = try #require(upload.formFields["key"])
    #expect(objectPath.hasPrefix("robin/") && objectPath.count == 70)
    #expect(upload.formFields["X-Amz-Signature"]?.count == 64)
    let policy = try #require(upload.formFields["Policy"].flatMap { Data(base64Encoded: $0) })
    #expect(String(decoding: policy, as: UTF8.self).contains("content-length-range"))
    #expect(download.method == "GET")
    #expect(download.url.absoluteString.contains("X-Amz-Signature="))
    #expect(download.url.path == "/uploads/\(objectPath)")
    var paths = Set<String>()
    for tenant in ["a//b", "a/b/", "a/../b", "a%2Fb", "日本語"] {
      let scoped = try self.key(tenant: tenant)
      let intent = try await storage.intent(
        for: scoped, operation: .download, expiresAt: date.addingTimeInterval(300))
      #expect(paths.insert(intent.url.path).inserted)
    }
  }

  @Test func liveS3ProviderConformance() async throws {
    guard ProcessInfo.processInfo.environment["ROBIN_S3_TESTS"] == "1" else { return }
    let endpoint = try #require(URL(string: "http://127.0.0.1:59000"))
    let date = Date()
    let storage = S3CompatibleStorage(
      configuration: try S3Configuration(
        endpoint: endpoint, bucket: "robin-tests", region: "us-east-1",
        accessKeyID: "robin-access", secretAccessKey: "robin-secret123",
        keyPrefix: "conformance-\(UUID().uuidString)"),
      now: { date })
    let first = try key(tenant: "a//b")
    let second = try key(tenant: "a/b/")
    let policy = StoragePolicy(contentTypes: ["text/plain"], maximumBytes: 5)
    _ = try await storage.put(
      StorageWrite(
        key: first, contentType: "text/plain", policy: policy,
        body: .bytes(Data("first".utf8))))
    _ = try await storage.put(
      StorageWrite(
        key: second, contentType: "text/plain", policy: policy,
        body: .bytes(Data("other".utf8))))

    #expect(try await bytes(storage.object(for: first)) == Data("first".utf8))
    #expect(try await storage.object(for: .init(first.object, tenant: .none)) == nil)
    #expect(try await storage.remove(first))
    #expect(try await storage.removeCreated(before: date.addingTimeInterval(1), limit: 1) == 1)
    #expect(try await storage.object(for: second) == nil)
  }

  private func key(tenant: String) throws -> ScopedObjectKey {
    ScopedObjectKey(
      try ObjectKey("avatars/user.txt"),
      tenant: .tenant(TenantContext(verified: tenant, source: .route)))
  }

  private func bytes(_ object: StoredObject?) async throws -> Data? {
    guard let object else { return nil }
    var data = Data()
    for try await chunk in object.body {
      data.append(contentsOf: chunk.readableBytesView)
    }
    return data
  }
}

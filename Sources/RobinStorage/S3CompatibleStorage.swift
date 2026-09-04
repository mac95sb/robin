import Crypto
import Foundation
import NIOCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
#if canImport(FoundationXML)
  import FoundationXML
#endif

/// Credentials and endpoint settings for an S3-compatible object store.
public struct S3Configuration: Sendable {
  /// Service endpoint, including its HTTP or HTTPS scheme.
  public let endpoint: URL
  /// Bucket name.
  public let bucket: String
  /// Signing region.
  public let region: String
  /// Access-key identity.
  public let accessKeyID: String
  /// Secret signing key.
  public let secretAccessKey: String
  /// Optional session token.
  public let sessionToken: String?
  /// Namespace reserved for Robin objects in the bucket.
  public let keyPrefix: String
  /// Whether the endpoint uses path-style bucket URLs.
  public let usesPathStyle: Bool
  /// Network timeout.
  public let timeout: TimeInterval

  /// Creates validated S3-compatible settings.
  public init(
    endpoint: URL,
    bucket: String,
    region: String,
    accessKeyID: String,
    secretAccessKey: String,
    sessionToken: String? = nil,
    keyPrefix: String = "robin",
    usesPathStyle: Bool = true,
    timeout: TimeInterval = 30
  ) throws {
    guard let scheme = endpoint.scheme?.lowercased(), scheme == "https" || scheme == "http",
      endpoint.host != nil,
      !bucket.isEmpty, !region.isEmpty, !accessKeyID.isEmpty, !secretAccessKey.isEmpty,
      !keyPrefix.isEmpty, !keyPrefix.hasPrefix("/"), !keyPrefix.hasSuffix("/"),
      !keyPrefix.split(separator: "/").contains(".."), timeout > 0
    else { throw StorageError.invalidRoot }
    self.endpoint = endpoint
    self.bucket = bucket
    self.region = region
    self.accessKeyID = accessKeyID
    self.secretAccessKey = secretAccessKey
    self.sessionToken = sessionToken
    self.keyPrefix = keyPrefix
    self.usesPathStyle = usesPathStyle
    self.timeout = timeout
  }
}

/// Production S3-compatible storage with AWS Signature Version 4 authentication.
public final class S3CompatibleStorage: Storage, StorageIntentSigner, Sendable {
  private let configuration: S3Configuration
  private let session: URLSession
  private let now: @Sendable () -> Date

  /// Creates an S3-compatible provider.
  public init(
    configuration: S3Configuration,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.configuration = configuration
    let sessionConfiguration = URLSessionConfiguration.ephemeral
    sessionConfiguration.timeoutIntervalForRequest = configuration.timeout
    sessionConfiguration.timeoutIntervalForResource = configuration.timeout
    self.session = URLSession(configuration: sessionConfiguration)
    self.now = now
  }

  /// Validates and uploads a streamed object.
  public func put(_ write: StorageWrite) async throws -> StorageMetadata {
    guard write.policy.contentTypes.isEmpty || write.policy.contentTypes.contains(write.contentType)
    else { throw StorageError.unsupportedContentType(write.contentType) }
    let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    _ = FileManager.default.createFile(atPath: temporary.path, contents: nil)
    defer { try? FileManager.default.removeItem(at: temporary) }
    let handle = try FileHandle(forWritingTo: temporary)
    var hasher = SHA256()
    var size: Int64 = 0
    do {
      for try await chunk in write.body {
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
    let checksum = Self.hexadecimal(hasher.finalize())
    if let expected = write.expectedChecksum, expected.lowercased() != checksum {
      throw StorageError.checksumMismatch(expected: expected, actual: checksum)
    }
    let date = now()
    let metadata = StorageMetadata(
      key: write.key.object.value,
      tenantIdentity: write.key.tenantIdentity,
      contentType: write.contentType,
      size: size,
      checksum: checksum,
      createdAt: date)
    var request = URLRequest(url: objectURL(for: s3Key(write.key)))
    request.httpMethod = "PUT"
    request.setValue(write.contentType, forHTTPHeaderField: "Content-Type")
    request.setValue(String(size), forHTTPHeaderField: "Content-Length")
    request.setValue(checksum, forHTTPHeaderField: "x-amz-content-sha256")
    request.setValue(
      Data(write.key.object.value.utf8).base64EncodedString(),
      forHTTPHeaderField: "x-amz-meta-robin-key")
    request.setValue(
      Data(write.key.tenantIdentity.utf8).base64EncodedString(),
      forHTTPHeaderField: "x-amz-meta-robin-tenant")
    request.setValue(checksum, forHTTPHeaderField: "x-amz-meta-robin-checksum")
    request.setValue(
      String(date.timeIntervalSince1970), forHTTPHeaderField: "x-amz-meta-robin-created")
    sign(&request, payloadHash: checksum, at: date)
    let (_, response) = try await session.upload(for: request, fromFile: temporary)
    try Self.accept(response, statuses: 200...299)
    return metadata
  }

  /// Downloads an object to an isolated temporary file and exposes streaming chunks.
  public func object(for key: ScopedObjectKey) async throws -> StoredObject? {
    var request = URLRequest(url: objectURL(for: s3Key(key)))
    request.httpMethod = "GET"
    sign(&request, payloadHash: Self.emptyHash, at: now())
    let (download, response) = try await session.download(for: request)
    guard let http = response as? HTTPURLResponse else { throw StorageError.providerResponse(0) }
    if http.statusCode == 404 { return nil }
    try Self.accept(http, statuses: 200...299)
    guard let encodedKey = http.value(forHTTPHeaderField: "x-amz-meta-robin-key"),
      let keyData = Data(base64Encoded: encodedKey),
      let encodedTenant = http.value(forHTTPHeaderField: "x-amz-meta-robin-tenant"),
      let tenantData = Data(base64Encoded: encodedTenant),
      let checksum = http.value(forHTTPHeaderField: "x-amz-meta-robin-checksum"),
      let createdText = http.value(forHTTPHeaderField: "x-amz-meta-robin-created"),
      let created = TimeInterval(createdText),
      String(decoding: keyData, as: UTF8.self) == key.object.value,
      String(decoding: tenantData, as: UTF8.self) == key.tenantIdentity
    else { throw StorageError.missingProviderMetadata }
    let file = try S3TemporaryFile(copying: download)
    let (size, actualChecksum) = try file.facts()
    guard actualChecksum == checksum else {
      throw StorageError.checksumMismatch(expected: checksum, actual: actualChecksum)
    }
    return StoredObject(
      metadata: StorageMetadata(
        key: key.object.value,
        tenantIdentity: key.tenantIdentity,
        contentType: http.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream",
        size: size,
        checksum: checksum,
        createdAt: Date(timeIntervalSince1970: created)),
      body: file.body)
  }

  /// Deletes one S3-compatible object.
  public func remove(_ key: ScopedObjectKey) async throws -> Bool {
    try await removeS3Key(s3Key(key))
  }

  /// Removes a bounded set of retained Robin objects from one listing page.
  public func removeCreated(before cutoff: Date, limit: Int) async throws -> Int {
    guard limit > 0 else { throw StorageError.invalidCleanupLimit }
    let bounded = min(limit, 1_000)
    let query =
      "list-type=2&max-keys=\(bounded)&prefix=\(Self.encode(configuration.keyPrefix + "/"))"
    var request = URLRequest(url: bucketURL(query: query))
    request.httpMethod = "GET"
    sign(&request, payloadHash: Self.emptyHash, at: now())
    let (data, response) = try await session.data(for: request)
    try Self.accept(response, statuses: 200...299)
    let listing = S3Listing.parse(data)
    var removed = 0
    // ponytail: one bounded S3 listing page avoids an unbounded cleanup pass; paginate if >1,000 deletions per run is measured as necessary.
    for object in listing where removed < bounded && object.modified < cutoff {
      if try await removeS3Key(object.key) { removed += 1 }
    }
    return removed
  }

  /// Creates a signed POST upload policy or presigned GET download request.
  public func intent(
    for key: ScopedObjectKey,
    operation: StorageIntentOperation,
    expiresAt: Date
  ) async throws -> SignedStorageIntent {
    let date = now()
    guard expiresAt > date else { throw StorageError.invalidRoot }
    switch operation {
    case .download:
      let url = presignedDownloadURL(key: s3Key(key), at: date, expiresAt: expiresAt)
      return SignedStorageIntent(url: url, method: "GET", headers: [:], expiresAt: expiresAt)
    case .upload(let contentType, let maximumBytes):
      guard maximumBytes >= 0 else { throw StorageError.sizeLimitExceeded(maximumBytes) }
      let fields = uploadPolicy(
        key: s3Key(key), contentType: contentType, maximumBytes: maximumBytes,
        at: date, expiresAt: expiresAt)
      return SignedStorageIntent(
        url: bucketURL(), method: "POST", formFields: fields, expiresAt: expiresAt)
    }
  }

  private func removeS3Key(_ key: String) async throws -> Bool {
    var request = URLRequest(url: objectURL(for: key))
    request.httpMethod = "DELETE"
    sign(&request, payloadHash: Self.emptyHash, at: now())
    let (_, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw StorageError.providerResponse(0) }
    if http.statusCode == 404 { return false }
    try Self.accept(http, statuses: 200...299)
    return true
  }

  private func s3Key(_ key: ScopedObjectKey) -> String {
    "\(configuration.keyPrefix)/\(key.tenantIdentity)/\(key.object.value)"
  }

  private func bucketURL(query: String? = nil) -> URL {
    var components = URLComponents(url: configuration.endpoint, resolvingAgainstBaseURL: false)!
    if configuration.usesPathStyle {
      components.percentEncodedPath = Self.path([configuration.bucket])
    } else {
      components.host = "\(configuration.bucket).\(components.host!)"
      components.percentEncodedPath = "/"
    }
    components.percentEncodedQuery = query
    return components.url!
  }

  private func objectURL(for key: String) -> URL {
    var components = URLComponents(url: configuration.endpoint, resolvingAgainstBaseURL: false)!
    if configuration.usesPathStyle {
      components.percentEncodedPath = Self.path([configuration.bucket, key])
    } else {
      components.host = "\(configuration.bucket).\(components.host!)"
      components.percentEncodedPath = Self.path([key])
    }
    return components.url!
  }

  private func sign(_ request: inout URLRequest, payloadHash: String, at date: Date) {
    let timestamp = Self.timestamp(date)
    request.setValue(timestamp.full, forHTTPHeaderField: "x-amz-date")
    if let token = configuration.sessionToken {
      request.setValue(token, forHTTPHeaderField: "x-amz-security-token")
    }
    let headers = Self.canonicalHeaders(request)
    let canonical = [
      request.httpMethod!, request.url!.percentEncodedPath,
      URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.percentEncodedQuery ?? "",
      headers.values, headers.names, payloadHash,
    ].joined(separator: "\n")
    let scope = "\(timestamp.short)/\(configuration.region)/s3/aws4_request"
    let stringToSign = "AWS4-HMAC-SHA256\n\(timestamp.full)\n\(scope)\n\(Self.hash(canonical))"
    let signature = Self.signature(
      stringToSign, secret: configuration.secretAccessKey,
      date: timestamp.short, region: configuration.region)
    request.setValue(
      "AWS4-HMAC-SHA256 Credential=\(configuration.accessKeyID)/\(scope), SignedHeaders=\(headers.names), Signature=\(signature)",
      forHTTPHeaderField: "Authorization")
  }

  private func presignedDownloadURL(key: String, at date: Date, expiresAt: Date) -> URL {
    let timestamp = Self.timestamp(date)
    let scope = "\(timestamp.short)/\(configuration.region)/s3/aws4_request"
    let base = objectURL(for: key)
    let host = base.hostHeader
    let expires = min(604_800, max(1, Int(expiresAt.timeIntervalSince(date))))
    var parameters = [
      "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
      "X-Amz-Credential": "\(configuration.accessKeyID)/\(scope)",
      "X-Amz-Date": timestamp.full,
      "X-Amz-Expires": String(expires),
      "X-Amz-SignedHeaders": "host",
    ]
    if let token = configuration.sessionToken { parameters["X-Amz-Security-Token"] = token }
    let query = Self.query(parameters)
    let canonical =
      "GET\n\(base.percentEncodedPath)\n\(query)\nhost:\(host)\n\nhost\nUNSIGNED-PAYLOAD"
    let stringToSign = "AWS4-HMAC-SHA256\n\(timestamp.full)\n\(scope)\n\(Self.hash(canonical))"
    parameters["X-Amz-Signature"] = Self.signature(
      stringToSign, secret: configuration.secretAccessKey,
      date: timestamp.short, region: configuration.region)
    var components = URLComponents(url: base, resolvingAgainstBaseURL: false)!
    components.percentEncodedQuery = Self.query(parameters)
    return components.url!
  }

  private func uploadPolicy(
    key: String, contentType: String, maximumBytes: Int64, at date: Date, expiresAt: Date
  ) -> [String: String] {
    let timestamp = Self.timestamp(date)
    let scope = "\(timestamp.short)/\(configuration.region)/s3/aws4_request"
    var conditions: [[String: String]] = [
      ["bucket": configuration.bucket], ["key": key], ["Content-Type": contentType],
      ["x-amz-algorithm": "AWS4-HMAC-SHA256"],
      ["x-amz-credential": "\(configuration.accessKeyID)/\(scope)"],
      ["x-amz-date": timestamp.full],
    ]
    if let token = configuration.sessionToken { conditions.append(["x-amz-security-token": token]) }
    let policy: [String: Any] = [
      "expiration": Self.iso8601(expiresAt),
      "conditions": conditions.map { $0 as Any } + [["content-length-range", 0, maximumBytes]],
    ]
    let data = try! JSONSerialization.data(withJSONObject: policy, options: [.sortedKeys])
    let encoded = data.base64EncodedString()
    var fields = [
      "key": key,
      "Content-Type": contentType,
      "Policy": encoded,
      "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
      "X-Amz-Credential": "\(configuration.accessKeyID)/\(scope)",
      "X-Amz-Date": timestamp.full,
      "X-Amz-Signature": Self.signature(
        encoded, secret: configuration.secretAccessKey,
        date: timestamp.short, region: configuration.region),
    ]
    if let token = configuration.sessionToken { fields["X-Amz-Security-Token"] = token }
    return fields
  }

  private static func accept(_ response: URLResponse, statuses: ClosedRange<Int>) throws {
    guard let http = response as? HTTPURLResponse else { throw StorageError.providerResponse(0) }
    guard statuses.contains(http.statusCode) else {
      throw StorageError.providerResponse(http.statusCode)
    }
  }

  private static let emptyHash = hash("")

  private static func hash(_ value: String) -> String {
    hexadecimal(SHA256.hash(data: Data(value.utf8)))
  }

  private static func signature(_ value: String, secret: String, date: String, region: String)
    -> String
  {
    let dateKey = hmac(Data(date.utf8), key: Data("AWS4\(secret)".utf8))
    let regionKey = hmac(Data(region.utf8), key: dateKey)
    let serviceKey = hmac(Data("s3".utf8), key: regionKey)
    let signingKey = hmac(Data("aws4_request".utf8), key: serviceKey)
    return hexadecimal(
      HMAC<SHA256>.authenticationCode(
        for: Data(value.utf8), using: SymmetricKey(data: signingKey)))
  }

  private static func hmac(_ value: Data, key: Data) -> Data {
    Data(HMAC<SHA256>.authenticationCode(for: value, using: SymmetricKey(data: key)))
  }

  private static func hexadecimal<Bytes: Sequence>(_ bytes: Bytes) -> String
  where Bytes.Element == UInt8 {
    let digits = Array("0123456789abcdef".utf8)
    return String(
      decoding: bytes.flatMap { [digits[Int($0 >> 4)], digits[Int($0 & 0x0f)]] },
      as: UTF8.self)
  }

  private static func canonicalHeaders(_ request: URLRequest) -> (names: String, values: String) {
    var values = request.allHTTPHeaderFields ?? [:]
    values["Host"] = request.url!.hostHeader
    let headers = values.map {
      ($0.key.lowercased(), $0.value.trimmingCharacters(in: .whitespaces))
    }
    .sorted { $0.0 < $1.0 }
    return (
      headers.map(\.0).joined(separator: ";"),
      headers.map { "\($0.0):\($0.1)\n" }.joined()
    )
  }

  private static func timestamp(_ date: Date) -> (full: String, short: String) {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    let full = formatter.string(from: date)
    return (full, String(full.prefix(8)))
  }

  private static func iso8601(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }

  private static func path(_ components: [String]) -> String {
    "/"
      + components.flatMap { $0.split(separator: "/").map(String.init) }
      .map(encode).joined(separator: "/")
  }

  private static func query(_ values: [String: String]) -> String {
    values.map { (encode($0.key), encode($0.value)) }.sorted { $0.0 < $1.0 }
      .map { "\($0)=\($1)" }.joined(separator: "&")
  }

  fileprivate static func encode(_ value: String) -> String {
    value.addingPercentEncoding(
      withAllowedCharacters: CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"))!
  }
}

extension URL {
  fileprivate var percentEncodedPath: String {
    URLComponents(url: self, resolvingAgainstBaseURL: false)?.percentEncodedPath ?? "/"
  }

  fileprivate var hostHeader: String {
    guard let port else { return host! }
    return "\(host!):\(port)"
  }
}

private final class S3Listing: NSObject, XMLParserDelegate, @unchecked Sendable {
  struct Object: Sendable {
    let key: String
    let modified: Date
  }

  private var element = ""
  private var text = ""
  private var key: String?
  private var modified: Date?
  private(set) var objects: [Object] = []

  static func parse(_ data: Data) -> [Object] {
    let delegate = S3Listing()
    let parser = XMLParser(data: data)
    #if canImport(Darwin)
      unsafe parser.delegate = delegate
    #else
      parser.delegate = delegate
    #endif
    _ = parser.parse()
    return delegate.objects
  }

  func parser(
    _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
  ) {
    element = elementName
    text = ""
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) { text += string }

  func parser(
    _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    if elementName == "Key" { key = text }
    if elementName == "LastModified" {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      modified = formatter.date(from: text)
    }
    if elementName == "Contents", let key, let modified {
      objects.append(Object(key: key, modified: modified))
      self.key = nil
      self.modified = nil
    }
    element = ""
  }
}

private final class S3TemporaryFile: @unchecked Sendable {
  let url: URL

  init(copying source: URL) throws {
    self.url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "robin-s3-\(UUID().uuidString)")
    try FileManager.default.copyItem(at: source, to: url)
  }

  deinit { try? FileManager.default.removeItem(at: url) }

  func facts() throws -> (size: Int64, checksum: String) {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var hasher = SHA256()
    var size: Int64 = 0
    while let data = try handle.read(upToCount: 64 * 1_024), !data.isEmpty {
      size += Int64(data.count)
      hasher.update(data: data)
    }
    let digest = hasher.finalize()
    let digits = Array("0123456789abcdef".utf8)
    let checksum = String(
      decoding: digest.flatMap { [digits[Int($0 >> 4)], digits[Int($0 & 0x0f)]] },
      as: UTF8.self)
    return (size, checksum)
  }

  var body: StorageBody {
    StorageBody { [self] in
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

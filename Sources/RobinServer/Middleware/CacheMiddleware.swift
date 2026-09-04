import Foundation
import HTTPTypes
import RobinCache
import RobinCore

extension Middleware {
  /// Caches read responses through provider-neutral operations.
  public static func cache(
    lookup: @escaping @Sendable (Request, RequestContext) async throws -> Response?,
    store: @escaping @Sendable (Response, Request, RequestContext) async throws -> Void
  ) -> Self {
    Self { request, context, next in
      guard ["GET", "HEAD"].contains(request.method.rawValue.uppercased()) else {
        return try await next.respond(to: request, context: context)
      }
      guard context.sessionID == nil, context.principal == nil else {
        return try await next.respond(to: request, context: context)
      }
      if let cached = try await lookup(request, context) { return cached }
      let response = try await next.respond(to: request, context: context)
      if response.head.status == .ok, response.head.headerFields[.setCookie] == nil,
        response.body.bufferedBytes != nil
      {
        try await store(response, request, context)
      }
      return response
    }
  }

  /// Caches buffered successful responses with explicit tenant and visibility boundaries.
  public static func cache(
    _ cache: Cache,
    policy: CachePolicy,
    tags: @escaping @Sendable (Request, RequestContext) -> Set<CacheTag> = { _, _ in [] },
    key: @escaping @Sendable (Request, RequestContext) throws -> ResponseCacheKey?
  ) -> Self {
    Self { request, context, next in
      guard ["GET", "HEAD"].contains(request.method.rawValue.uppercased()),
        let key = try key(request, context), key.matches(context)
      else { return try await next.respond(to: request, context: context) }

      if let hit = try await cache.value(for: key.key) {
        let response = hit.value.response(
          method: request.method,
          entityTag: hit.entityTag,
          lastModified: hit.lastModified
        )
        if hit.validators.isNotModified(
          ifNoneMatch: request.header(.ifNoneMatch),
          ifModifiedSince: request.header(.ifModifiedSince).flatMap(httpDate)
        ) {
          return Response(
            status: .notModified,
            headers: [.eTag: hit.entityTag, .lastModified: httpDate(hit.lastModified)]
          )
        }
        if hit.freshness == .stale, request.method == .get {
          Task {
            guard let refreshed = try? await next.respond(to: request, context: context) else {
              return
            }
            try? await store(
              refreshed, in: cache, for: key, policy: policy, tags: tags(request, context))
          }
        }
        return response
      }

      let response = try await next.respond(to: request, context: context)
      if request.method == .get {
        try await store(response, in: cache, for: key, policy: policy, tags: tags(request, context))
      }
      return response
    }
  }
}

/// A typed response-cache identity with explicit representation boundaries.
public struct ResponseCacheKey: Sendable {
  fileprivate let key: CacheKey<CachedResponse>
  private let context: CacheContext

  /// Creates a page or fragment response-cache key.
  public init(namespace: String = "page", value: String, context: CacheContext) throws {
    self.key = try CacheKey(namespace: namespace, value: value, context: context)
    self.context = context
  }

  fileprivate func matches(_ request: RequestContext) -> Bool {
    let requestTenant: TenantScope<String> = request.tenant.map(TenantScope.tenant) ?? .none
    guard requestTenant == context.tenant else { return false }
    switch context.visibility {
    case .shared:
      return request.sessionID == nil && request.principal == nil
    case .privateTo(let subject):
      return request.principal?.id == subject
    }
  }
}

private struct CachedResponse: Codable, Sendable {
  struct Header: Codable, Sendable {
    let name: String
    let value: String
  }

  let status: Int
  let headers: [Header]
  let body: [UInt8]

  init?(_ response: Response) {
    guard response.head.status == .ok, response.head.headerFields[.setCookie] == nil,
      let body = response.body.bufferedBytes
    else { return nil }
    status = response.head.status.code
    headers = response.head.headerFields.map {
      Header(name: $0.name.canonicalName, value: $0.value)
    }
    self.body = body
  }

  func response(method: HTTPRequest.Method, entityTag: String, lastModified: Date) -> Response {
    var fields = HTTPFields()
    for header in headers {
      if let name = HTTPField.Name(header.name) {
        fields.append(HTTPField(name: name, value: header.value))
      }
    }
    fields[.eTag] = entityTag
    fields[.lastModified] = httpDate(lastModified)
    return Response(
      status: HTTPResponse.Status(code: status),
      headers: fields,
      body: method == .head ? [] : body
    )
  }
}

private func store(
  _ response: Response,
  in cache: Cache,
  for key: ResponseCacheKey,
  policy: CachePolicy,
  tags: Set<CacheTag>
) async throws {
  guard let response = CachedResponse(response) else { return }
  try await cache.store(response, for: key.key, policy: policy, tags: tags)
}

private func httpDate(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
  return formatter.string(from: date)
}

private func httpDate(_ value: String) -> Date? {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
  return formatter.date(from: value)
}

extension CachedValue {
  fileprivate var validators: CacheValidators {
    CacheValidators(entityTag: entityTag, lastModified: lastModified)
  }
}

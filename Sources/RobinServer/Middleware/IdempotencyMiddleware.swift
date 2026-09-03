import Crypto
import Foundation
import HTTPTypes

extension Middleware {
  private static let idempotencyKey = HTTPField.Name("idempotency-key")!

  /// Coalesces retried unsafe requests when the caller supplies an idempotency key.
  public static func idempotency(_ store: IdempotencyStore) -> Self {
    Self(requiredCapabilities: .processLocalState) { request, context, next in
      guard ["POST", "PUT", "PATCH", "DELETE"].contains(request.method.rawValue.uppercased()) else {
        return try await next.respond(to: request, context: context)
      }
      guard let key = request.header(idempotencyKey), !key.isEmpty else {
        return try await next.respond(to: request, context: context)
      }
      let identity = context.sessionID ?? context.tenant?.id ?? context.clientAddress ?? "anonymous"
      let digest = SHA256.hash(data: Data(request.body)).map { byte in
        let value = String(byte, radix: 16)
        return value.count == 1 ? "0\(value)" : value
      }.joined()
      let scopedKey = "\(identity):\(request.method.rawValue):\(request.target):\(key):\(digest)"
      return try await store.response(for: scopedKey) {
        try await next.respond(to: request, context: context)
      }
    }
  }
}

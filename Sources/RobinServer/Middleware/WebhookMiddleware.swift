import Crypto
import Foundation
import HTTPTypes

extension Middleware {
  /// Verifies an HMAC-SHA256 webhook signature, timestamp freshness, and replay identifier.
  ///
  /// The signature covers `<timestamp>.<raw body>` and may be supplied as lowercase hexadecimal
  /// with an optional `sha256=` prefix.
  public static func webhookSignature(
    secret: Data,
    replayProtector: ReplayProtector,
    tolerance: TimeInterval = 300,
    timestampHeader: HTTPField.Name = HTTPField.Name("x-webhook-timestamp")!,
    signatureHeader: HTTPField.Name = HTTPField.Name("x-webhook-signature")!
  ) -> Self {
    precondition(!secret.isEmpty && tolerance >= 0)
    let key = SymmetricKey(data: secret)
    return Self(requiredCapabilities: .processLocalState) { request, context, next in
      guard let rawTimestamp = request.header(timestampHeader),
        let timestamp = TimeInterval(rawTimestamp),
        abs(Date().timeIntervalSince1970 - timestamp) <= tolerance,
        let supplied = request.header(signatureHeader).flatMap(signatureBytes)
      else {
        return .text("Webhook verification failed", status: .unauthorized)
      }

      let message = Data(rawTimestamp.utf8) + Data([46]) + Data(request.body)
      guard HMAC<SHA256>.isValidAuthenticationCode(supplied, authenticating: message, using: key),
        await replayProtector.accept("\(rawTimestamp):\(supplied.hex)")
      else {
        return .text("Webhook verification failed", status: .unauthorized)
      }
      return try await next.respond(to: request, context: context)
    }
  }
}

private func signatureBytes(_ value: String) -> Data? {
  let hexadecimal = value.hasPrefix("sha256=") ? String(value.dropFirst(7)) : value
  guard hexadecimal.count == 64 else { return nil }
  var bytes: [UInt8] = []
  bytes.reserveCapacity(32)
  var index = hexadecimal.startIndex
  while index < hexadecimal.endIndex {
    let next = hexadecimal.index(index, offsetBy: 2)
    guard let byte = UInt8(hexadecimal[index..<next], radix: 16) else { return nil }
    bytes.append(byte)
    index = next
  }
  return Data(bytes)
}

extension Data {
  fileprivate var hex: String {
    map {
      let value = String($0, radix: 16)
      return value.count == 1 ? "0\(value)" : value
    }.joined()
  }
}

import Crypto
import Foundation

package func randomAuthToken(byteCount: Int = 32) -> String {
  var generator = SystemRandomNumberGenerator()
  return Data((0..<byteCount).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    .base64EncodedString()
    .replacingOccurrences(of: "+", with: "-")
    .replacingOccurrences(of: "/", with: "_")
    .replacingOccurrences(of: "=", with: "")
}

package func authDigest(_ value: String) -> String {
  let digits = Array("0123456789abcdef".utf8)
  let bytes = SHA256.hash(data: Data(value.utf8)).flatMap {
    [digits[Int($0 >> 4)], digits[Int($0 & 0x0f)]]
  }
  return String(decoding: bytes, as: UTF8.self)
}

package func normalizedEmail(_ value: String) -> String? {
  let email = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  guard email.split(separator: "@").count == 2, !email.contains(" ") else { return nil }
  return email
}

package func safeRedirect(_ value: String) -> Bool {
  value.hasPrefix("/") && !value.hasPrefix("//") && !value.contains("\\")
    && !value.contains("\r") && !value.contains("\n")
}

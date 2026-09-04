import Crypto
import Foundation

struct CSSSerialization {
  static func decimal(_ value: Double) -> String {
    String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), value)
      .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
      .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
  }

  static func stableHash(_ value: String) -> String {
    SHA256.hash(data: Data(value.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
  }
}

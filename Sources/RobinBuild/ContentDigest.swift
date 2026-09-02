import Crypto
import Foundation

enum ContentDigest {
  static func sha256(_ bytes: [UInt8]) -> String { hexadecimal(SHA256.hash(data: bytes)) }

  static func sha384Integrity(_ bytes: [UInt8]) -> String {
    "sha384-\(Data(SHA384.hash(data: bytes)).base64EncodedString())"
  }

  static func isSHA256(_ value: String) -> Bool {
    value.utf8.count == 64
      && value.utf8.allSatisfy {
        (48...57).contains($0) || (97...102).contains($0)
      }
  }

  private static func hexadecimal<D: Sequence>(_ digest: D) -> String where D.Element == UInt8 {
    let hexadecimal = Array("0123456789abcdef".utf8)
    var bytes: [UInt8] = []
    for byte in digest {
      bytes.append(hexadecimal[Int(byte >> 4)])
      bytes.append(hexadecimal[Int(byte & 0x0f)])
    }
    return String(decoding: bytes, as: UTF8.self)
  }
}

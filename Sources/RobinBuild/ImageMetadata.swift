/// Dimensions and encoding read from a raster image artifact.
public struct ImageMetadata: Codable, Equatable, Sendable {
  /// A raster image encoding recognized by RobinBuild.
  public enum Format: String, Codable, CaseIterable, Sendable {
    /// Portable Network Graphics.
    case png
    /// Joint Photographic Experts Group encoding.
    case jpeg
    /// Graphics Interchange Format.
    case gif
    /// WebP encoding.
    case webp
    /// AV1 Image File Format.
    case avif
  }

  /// The image width in pixels.
  public let width: Int
  /// The image height in pixels.
  public let height: Int
  /// The detected encoding.
  public let format: Format

  init?(bytes: [UInt8]) {
    if bytes.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]), bytes.count >= 24 {
      self.init(
        width: Self.bigEndian(bytes[16...19]), height: Self.bigEndian(bytes[20...23]), format: .png)
      return
    }
    if bytes.count >= 10, bytes[0...2] == Array("GIF".utf8)[...] {
      self.init(
        width: Int(bytes[6]) | Int(bytes[7]) << 8,
        height: Int(bytes[8]) | Int(bytes[9]) << 8,
        format: .gif
      )
      return
    }
    if let dimensions = Self.jpegDimensions(bytes) {
      self.init(width: dimensions.width, height: dimensions.height, format: .jpeg)
      return
    }
    if let dimensions = Self.webpDimensions(bytes) {
      self.init(width: dimensions.width, height: dimensions.height, format: .webp)
      return
    }
    if let dimensions = Self.avifDimensions(bytes) {
      self.init(width: dimensions.width, height: dimensions.height, format: .avif)
      return
    }
    return nil
  }

  private init(width: Int, height: Int, format: Format) {
    guard width > 0, height > 0 else {
      self.width = 0
      self.height = 0
      self.format = format
      return
    }
    self.width = width
    self.height = height
    self.format = format
  }

  private static func bigEndian(_ bytes: ArraySlice<UInt8>) -> Int {
    bytes.reduce(0) { $0 << 8 | Int($1) }
  }

  private static func jpegDimensions(_ bytes: [UInt8]) -> (width: Int, height: Int)? {
    guard bytes.starts(with: [0xff, 0xd8]) else { return nil }
    var index = 2
    let frameMarkers: Set<UInt8> = [
      0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf,
    ]
    while index + 8 < bytes.count {
      guard bytes[index] == 0xff else {
        index += 1
        continue
      }
      let marker = bytes[index + 1]
      if frameMarkers.contains(marker) {
        return (
          Int(bytes[index + 7]) << 8 | Int(bytes[index + 8]),
          Int(bytes[index + 5]) << 8 | Int(bytes[index + 6])
        )
      }
      guard index + 3 < bytes.count else { return nil }
      let length = Int(bytes[index + 2]) << 8 | Int(bytes[index + 3])
      guard length >= 2 else { return nil }
      index += 2 + length
    }
    return nil
  }

  private static func webpDimensions(_ bytes: [UInt8]) -> (width: Int, height: Int)? {
    guard bytes.count >= 30,
      String(decoding: bytes[0...3], as: UTF8.self) == "RIFF",
      String(decoding: bytes[8...11], as: UTF8.self) == "WEBP"
    else { return nil }
    let chunk = String(decoding: bytes[12...15], as: UTF8.self)
    if chunk == "VP8X" {
      return (
        1 + Int(bytes[24]) + (Int(bytes[25]) << 8) + (Int(bytes[26]) << 16),
        1 + Int(bytes[27]) + (Int(bytes[28]) << 8) + (Int(bytes[29]) << 16)
      )
    }
    if chunk == "VP8 ", bytes[23...25] == [0x9d, 0x01, 0x2a][...] {
      return (
        (Int(bytes[26]) | Int(bytes[27]) << 8) & 0x3fff,
        (Int(bytes[28]) | Int(bytes[29]) << 8) & 0x3fff
      )
    }
    if chunk == "VP8L", bytes[20] == 0x2f {
      return (
        1 + Int(bytes[21]) + ((Int(bytes[22]) & 0x3f) << 8),
        1 + ((Int(bytes[22]) & 0xc0) >> 6) + (Int(bytes[23]) << 2)
          + ((Int(bytes[24]) & 0x0f) << 10)
      )
    }
    return nil
  }

  private static func avifDimensions(_ bytes: [UInt8]) -> (width: Int, height: Int)? {
    guard bytes.count >= 24, containsASCII("avif", in: bytes) else { return nil }
    for index in 0...(bytes.count - 20) where bytes[index..<(index + 4)] == Array("ispe".utf8)[...]
    {
      let width = bigEndian(bytes[(index + 8)...(index + 11)])
      let height = bigEndian(bytes[(index + 12)...(index + 15)])
      if width > 0, height > 0 { return (width, height) }
    }
    return nil
  }

  private static func containsASCII(_ value: String, in bytes: [UInt8]) -> Bool {
    let needle = Array(value.utf8)
    guard bytes.count >= needle.count else { return false }
    return (0...(bytes.count - needle.count)).contains {
      Array(bytes[$0..<($0 + needle.count)]) == needle
    }
  }
}

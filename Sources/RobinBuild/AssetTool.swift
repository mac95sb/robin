import Foundation

/// A checksum-pinned executable used for a reproducible asset transform.
public struct AssetTool: Sendable {
  /// The executable file URL.
  public let executable: URL
  /// The expected SHA-256 digest of the executable bytes, normalized to lowercase.
  public let expectedDigest: String

  /// Creates a pinned asset tool.
  ///
  /// - Parameters:
  ///   - executable: The executable file URL.
  ///   - expectedDigest: Its 64-character hexadecimal SHA-256 digest.
  public init(executable: URL, expectedDigest: String) {
    self.executable = executable
    self.expectedDigest = expectedDigest.lowercased()
  }
}

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

/// External tools available to deterministic asset transforms.
public struct AssetToolchain: Sendable {
  /// A libvips executable.
  public var image: AssetTool?
  /// A `usvg` executable.
  public var svg: AssetTool?
  /// A HarfBuzz `hb-subset` executable.
  public var font: AssetTool?
  /// An esbuild-compatible script executable.
  public var script: AssetTool?

  /// Creates an asset toolchain.
  ///
  /// - Parameters:
  ///   - image: A libvips executable.
  ///   - svg: A `usvg` executable.
  ///   - font: A HarfBuzz `hb-subset` executable.
  ///   - script: An esbuild-compatible executable.
  public init(
    image: AssetTool? = nil,
    svg: AssetTool? = nil,
    font: AssetTool? = nil,
    script: AssetTool? = nil
  ) {
    self.image = image
    self.svg = svg
    self.font = font
    self.script = script
  }
}

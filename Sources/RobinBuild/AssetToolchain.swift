import Foundation

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

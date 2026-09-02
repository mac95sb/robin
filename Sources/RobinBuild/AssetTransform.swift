/// A deterministic transformation applied to a typed asset.
public enum AssetTransform: Equatable, Sendable {
  /// Normalize and optimize an SVG with the configured `usvg` tool.
  case optimizeSVG
  /// Resize and encode an image with the configured libvips tool.
  case resizeImage(width: Int, format: ImageFormat)
  /// Subset a font with the configured HarfBuzz `hb-subset` tool.
  case subsetFont(characters: String)
  /// Bundle an application script with the configured esbuild-compatible tool.
  case bundleScript

  /// A browser image encoding produced by an image transform.
  public enum ImageFormat: String, CaseIterable, Sendable {
    /// WebP image data.
    case webp
    /// AVIF image data.
    case avif
  }

  var identifier: String {
    switch self {
    case .optimizeSVG: "svg:optimize"
    case .resizeImage(let width, let format): "image:\(width):\(format.rawValue)"
    case .subsetFont(let characters):
      "font:subset:\(ContentDigest.sha256(Array(characters.utf8)))"
    case .bundleScript: "script:bundle"
    }
  }
}

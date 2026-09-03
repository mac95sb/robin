import Foundation

/// A deterministic record of materialized build artifacts.
public struct BuildManifest: Codable, Equatable, Sendable {
  /// One artifact recorded in a build manifest.
  public struct Entry: Codable, Equatable, Sendable {
    /// The artifact's deployment role.
    public let kind: BuildArtifact.Kind
    /// The portable path relative to the build output root.
    public let path: String
    /// The lowercase hexadecimal SHA-256 digest of the file contents.
    public let digest: String
    /// The file size in bytes.
    public let byteCount: Int
    /// Paths of artifacts that precede this artifact.
    public let dependencies: [String]
    /// The MIME type of the file, when known.
    public let mediaType: String?
    /// The subresource-integrity value, when generated.
    public let integrity: String?
    /// Deterministic transforms applied in source order.
    public let transforms: [String]
    /// The typed reason a JavaScript artifact is present.
    public let scriptOrigin: ScriptOrigin?
    /// Raster image dimensions and encoding, when applicable.
    public let imageMetadata: ImageMetadata?
  }

  /// Artifacts in stable dependency order.
  public let artifacts: [Entry]

  /// Encodes the manifest as deterministic JSON.
  ///
  /// - Returns: UTF-8 JSON with sorted object keys.
  /// - Throws: An encoding error if the manifest cannot be represented as JSON.
  public func encoded() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(self)
  }
}

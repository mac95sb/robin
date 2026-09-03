/// A typed local asset processed and fingerprinted by RobinBuild.
public struct BuildAsset: Sendable {
  /// The application-facing absolute reference, such as `/images/logo.svg`.
  public let reference: String
  /// The unfingerprinted relative output path.
  public let path: String
  /// The source bytes.
  public let bytes: [UInt8]
  /// The source MIME type, updated by transforms when the output encoding changes.
  public let mediaType: String
  /// Deterministic transforms applied in source order.
  public let transforms: [AssetTransform]
  /// Browser delivery hints associated with the final artifact.
  public let hints: [ResourceHint]
  /// The typed reason for a JavaScript asset.
  public let scriptOrigin: ScriptOrigin?

  /// Creates a typed asset.
  ///
  /// - Parameters:
  ///   - reference: The absolute reference used by components.
  ///   - path: The relative output path before fingerprinting.
  ///   - bytes: The source bytes.
  ///   - mediaType: The source MIME type before transforms run.
  ///   - transforms: Deterministic transforms applied in source order.
  ///   - hints: Browser delivery hints for the final artifact.
  ///   - scriptOrigin: The typed reason for a JavaScript asset.
  /// - Throws: ``BuildError/invalidArtifactPath(_:)`` for invalid references or paths.
  public init(
    reference: String,
    path: String,
    bytes: [UInt8],
    mediaType: String,
    transforms: [AssetTransform] = [],
    hints: [ResourceHint] = [],
    scriptOrigin: ScriptOrigin? = nil
  ) throws {
    guard reference.hasPrefix("/"), !reference.hasPrefix("//"),
      BuildArtifact.isValid(String(reference.dropFirst())), BuildArtifact.isValid(path)
    else { throw BuildError.invalidArtifactPath(reference) }
    self.reference = reference
    self.path = path
    self.bytes = bytes
    self.mediaType = mediaType
    self.transforms = transforms
    self.hints = hints
    self.scriptOrigin = scriptOrigin
  }
}

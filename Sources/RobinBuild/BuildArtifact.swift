/// One final file in a provider-neutral build artifact graph.
public struct BuildArtifact: Equatable, Sendable {
  /// The deployment role of an artifact.
  public enum Kind: String, Codable, CaseIterable, Hashable, Sendable {
    /// A file served directly by a static host or asset server.
    case staticFile
    /// A standalone persistent server executable.
    case executable
    /// An executable or archive containing one deployable function.
    case functionBundle
    /// A library required by an executable artifact.
    case runtimeLibrary
    /// Typed routing metadata encoded for a deployment target.
    case routeManifest
    /// Deployment metadata that is not a routing manifest.
    case deploymentMetadata
  }

  /// The artifact's role in deployment output.
  public let kind: Kind
  /// The portable path relative to the build output root.
  public let path: String
  /// The final file contents.
  public let bytes: [UInt8]
  /// Paths of artifacts that must precede this artifact.
  public let dependencies: [String]
  /// The MIME type of the file, when known.
  public let mediaType: String?
  /// The subresource-integrity value for a browser-consumable artifact.
  public let integrity: String?
  /// Deterministic transforms applied in source order.
  public let transforms: [String]
  /// The typed reason a JavaScript artifact is present.
  public let scriptOrigin: ScriptOrigin?
  /// Raster image dimensions and encoding, when applicable.
  public let imageMetadata: ImageMetadata?

  /// Creates a final build artifact.
  ///
  /// - Parameters:
  ///   - kind: The artifact's deployment role.
  ///   - path: A nonempty relative path using `/` separators.
  ///   - bytes: The final file contents.
  ///   - dependencies: Relative artifact paths that must precede this artifact.
  ///   - mediaType: The MIME type of the final file.
  ///   - integrity: The final file's subresource-integrity value.
  ///   - transforms: Deterministic transforms applied in source order.
  ///   - scriptOrigin: The typed reason a JavaScript artifact is allowed.
  ///   - imageMetadata: Raster image dimensions and encoding.
  /// - Throws: ``BuildError/invalidArtifactPath(_:)`` for an unsafe path or dependency.
  public init(
    kind: Kind,
    path: String,
    bytes: [UInt8],
    dependencies: [String] = [],
    mediaType: String? = nil,
    integrity: String? = nil,
    transforms: [String] = [],
    scriptOrigin: ScriptOrigin? = nil,
    imageMetadata: ImageMetadata? = nil
  ) throws {
    guard Self.isValid(path), path != "manifest.json" else {
      throw BuildError.invalidArtifactPath(path)
    }
    for dependency in dependencies where !Self.isValid(dependency) {
      throw BuildError.invalidArtifactPath(dependency)
    }
    let isJavaScript =
      path.hasSuffix(".js") || path.hasSuffix(".mjs")
      || mediaType == "text/javascript" || mediaType == "application/javascript"
    guard !isJavaScript || scriptOrigin?.isValid == true else {
      throw BuildError.unexplainedScript(path)
    }
    guard isJavaScript || scriptOrigin == nil else {
      throw BuildError.invalidScriptOrigin(path)
    }
    self.kind = kind
    self.path = path
    self.bytes = bytes
    self.dependencies = Array(Set(dependencies)).sorted()
    self.mediaType = mediaType
    self.integrity = integrity
    self.transforms = transforms
    self.scriptOrigin = scriptOrigin
    self.imageMetadata = imageMetadata
  }

  static func isValid(_ path: String) -> Bool {
    guard !path.isEmpty, !path.hasPrefix("/"), !path.contains("\\") else { return false }
    return path.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
      !$0.isEmpty && $0 != "." && $0 != ".."
    }
  }
}

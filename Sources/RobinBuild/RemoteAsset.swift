import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A typed asset downloaded only during an asynchronous build.
public struct RemoteAsset: Sendable {
  /// The remote source URL.
  public let url: URL
  /// The expected SHA-256 digest, normalized to lowercase and required in production.
  public let expectedDigest: String?
  /// The application-facing absolute reference.
  public let reference: String
  /// The unfingerprinted relative output path.
  public let path: String
  /// The source MIME type, updated by transforms when the output encoding changes.
  public let mediaType: String
  /// Deterministic transforms applied after download.
  public let transforms: [AssetTransform]
  /// Browser delivery hints associated with the final artifact.
  public let hints: [ResourceHint]
  /// The typed reason for a JavaScript asset.
  public let scriptOrigin: ScriptOrigin?

  /// Creates a remote build-time asset declaration.
  ///
  /// - Parameters:
  ///   - url: The HTTPS source URL fetched only during a build.
  ///   - expectedDigest: The expected 64-character hexadecimal SHA-256 digest.
  ///   - reference: The absolute reference used by components.
  ///   - path: The relative output path before fingerprinting.
  ///   - mediaType: The source MIME type before transforms run.
  ///   - transforms: Deterministic transforms applied after download.
  ///   - hints: Browser delivery hints for the final artifact.
  ///   - scriptOrigin: The typed reason for a JavaScript asset.
  /// - Throws: ``BuildError`` when the URL, reference, or path is invalid.
  public init(
    url: URL,
    expectedDigest: String? = nil,
    reference: String,
    path: String,
    mediaType: String,
    transforms: [AssetTransform] = [],
    hints: [ResourceHint] = [],
    scriptOrigin: ScriptOrigin? = nil
  ) throws {
    guard url.scheme == "https" else { throw BuildError.remoteAssetUnavailable(Self.redacted(url)) }
    if let expectedDigest, !ContentDigest.isSHA256(expectedDigest.lowercased()) {
      throw BuildError.invalidDigest("remote asset")
    }
    _ = try BuildAsset(
      reference: reference,
      path: path,
      bytes: [],
      mediaType: mediaType,
      transforms: transforms,
      hints: hints,
      scriptOrigin: scriptOrigin
    )
    self.url = url
    self.expectedDigest = expectedDigest?.lowercased()
    self.reference = reference
    self.path = path
    self.mediaType = mediaType
    self.transforms = transforms
    self.hints = hints
    self.scriptOrigin = scriptOrigin
  }

  func resolve(environment: BuildEnvironment, layout: OutputLayout) async throws -> BuildAsset {
    if environment == .production, expectedDigest == nil {
      throw BuildError.unpinnedRemoteAsset(diagnosticURL)
    }
    let cacheRoot = layout.path(for: .cache).appendingPathComponent("remote", isDirectory: true)
    if let expectedDigest {
      let cached = cacheRoot.appendingPathComponent(expectedDigest)
      if FileManager.default.fileExists(atPath: cached.path()) {
        let bytes = Array(try Data(contentsOf: cached))
        guard ContentDigest.sha256(bytes) == expectedDigest else {
          throw BuildError.remoteAssetDigestMismatch(diagnosticURL)
        }
        return try resolvedAsset(bytes: bytes)
      }
    }

    let data: Data
    do {
      let (downloaded, response) = try await URLSession.shared.data(from: url)
      guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
        response.url?.scheme == "https"
      else {
        throw BuildError.remoteAssetUnavailable(diagnosticURL)
      }
      data = downloaded
    } catch let error as BuildError {
      throw error
    } catch {
      throw BuildError.remoteAssetUnavailable(diagnosticURL)
    }
    let bytes = Array(data)
    let digest = ContentDigest.sha256(bytes)
    if let expectedDigest, digest != expectedDigest {
      throw BuildError.remoteAssetDigestMismatch(diagnosticURL)
    }
    guard layout.contains(cacheRoot) else {
      throw BuildError.outputEscapesRobinRoot(cacheRoot.path())
    }
    try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
    let cached = cacheRoot.appendingPathComponent(digest)
    if !FileManager.default.fileExists(atPath: cached.path()) {
      try data.write(to: cached, options: .atomic)
    }
    return try resolvedAsset(bytes: bytes)
  }

  private func resolvedAsset(bytes: [UInt8]) throws -> BuildAsset {
    try BuildAsset(
      reference: reference,
      path: path,
      bytes: bytes,
      mediaType: mediaType,
      transforms: transforms,
      hints: hints,
      scriptOrigin: scriptOrigin
    )
  }

  private var diagnosticURL: String { Self.redacted(url) }

  private static func redacted(_ url: URL) -> String {
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.user = nil
    components?.password = nil
    components?.query = nil
    components?.fragment = nil
    return components?.string ?? "remote asset"
  }
}

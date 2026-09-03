import Foundation
import RobinCore
import RobinHTML

struct ProcessedAssets {
  struct Reference {
    let outputPath: String
    let browserURL: String
  }

  let artifacts: [BuildArtifact]
  let references: [String: Reference]
  let headElements: [String]
}

struct AssetProcessor {
  static func process(
    _ assets: [BuildAsset],
    toolchain: AssetToolchain,
    cdnBaseURL: URL?,
    layout: OutputLayout
  ) throws -> ProcessedAssets {
    var artifacts: [BuildArtifact] = []
    var references: [String: ProcessedAssets.Reference] = [:]
    var headElements: [String] = []
    for asset in assets.sorted(by: { $0.path < $1.path }) {
      var bytes = asset.bytes
      for transform in asset.transforms {
        bytes = try apply(transform, to: bytes, asset: asset, toolchain: toolchain, layout: layout)
      }
      let final = finalIdentity(for: asset)
      let outputPath = fingerprintedPath(final.path, bytes: bytes)
      let integrity = ContentDigest.sha384Integrity(bytes)
      let imageMetadata = ImageMetadata(bytes: bytes)
      if final.mediaType.hasPrefix("image/"), final.mediaType != "image/svg+xml",
        imageMetadata == nil || imageMetadata?.width == 0 || imageMetadata?.height == 0
      {
        throw BuildError.invalidImage(asset.reference)
      }
      let artifact = try BuildArtifact(
        kind: .staticFile,
        path: outputPath,
        bytes: bytes,
        mediaType: final.mediaType,
        integrity: integrity,
        transforms: asset.transforms.map { recordedIdentifier($0, toolchain: toolchain) },
        scriptOrigin: asset.scriptOrigin,
        imageMetadata: imageMetadata
      )
      artifacts.append(artifact)
      let browserURL =
        cdnBaseURL.map {
          $0.appendingPathComponent(outputPath).absoluteString
        } ?? "/\(outputPath)"
      guard
        references.updateValue(
          .init(outputPath: outputPath, browserURL: browserURL), forKey: asset.reference) == nil
      else { throw BuildError.duplicateArtifactPath(asset.reference) }
      for hint in asset.hints {
        try validate(hint, mediaType: final.mediaType, reference: asset.reference)
        headElements.append(
          headElement(
            for: hint,
            assetURL: browserURL,
            integrity: integrity,
            crossOrigin: cdnBaseURL != nil
          ))
      }
    }
    return ProcessedAssets(
      artifacts: artifacts,
      references: references,
      headElements: Array(Set(headElements)).sorted()
    )
  }

  private static func validate(
    _ hint: ResourceHint,
    mediaType: String,
    reference: String
  ) throws {
    switch hint {
    case .preload(let destination):
      let valid =
        switch destination {
        case .style: mediaType == "text/css"
        case .script:
          mediaType == "text/javascript" || mediaType == "application/javascript"
        case .image: mediaType.hasPrefix("image/")
        case .font: mediaType.hasPrefix("font/")
        case .fetch: true
        }
      guard valid else { throw BuildError.invalidResourceHint(reference) }
    case .preconnect(let origin):
      guard let components = URLComponents(string: origin), components.scheme == "https",
        components.host != nil, components.user == nil, components.password == nil,
        components.query == nil, components.fragment == nil,
        components.path.isEmpty || components.path == "/"
      else { throw BuildError.invalidResourceHint("preconnect origin") }
    }
  }

  private static func finalIdentity(for asset: BuildAsset) -> (path: String, mediaType: String) {
    var path = asset.path
    var mediaType = asset.mediaType
    for transform in asset.transforms {
      switch transform {
      case .resizeImage(_, let format):
        path = replacingExtension(of: path, with: format.rawValue)
        mediaType = "image/\(format.rawValue)"
      case .bundleScript:
        path = replacingExtension(of: path, with: "js")
        mediaType = "text/javascript"
      case .optimizeSVG, .subsetFont: break
      }
    }
    return (path, mediaType)
  }

  private static func replacingExtension(of path: String, with suffix: String) -> String {
    guard let dot = path.lastIndex(of: ".") else { return "\(path).\(suffix)" }
    return "\(path[..<dot]).\(suffix)"
  }

  private static func fingerprintedPath(_ path: String, bytes: [UInt8]) -> String {
    let components = path.split(separator: "/").map(String.init)
    let filename = components.last!
    let dot = filename.lastIndex(of: ".")
    let stem = dot.map { String(filename[..<$0]) } ?? filename
    let suffix = dot.map { String(filename[$0...]) } ?? ""
    let fingerprinted = "\(stem)-\(ContentDigest.sha256(bytes).prefix(12))\(suffix)"
    return (Array(components.dropLast()) + [fingerprinted]).joined(separator: "/")
  }

  private static func headElement(
    for hint: ResourceHint,
    assetURL: String,
    integrity: String,
    crossOrigin: Bool
  ) -> String {
    switch hint {
    case .preload(let destination):
      let crossorigin = destination == .font || crossOrigin ? " crossorigin=\"anonymous\"" : ""
      return
        "<link rel=\"preload\" href=\"\(HTMLRenderer.escape(assetURL))\" as=\"\(destination.rawValue)\" integrity=\"\(integrity)\"\(crossorigin)>"
    case .preconnect(let origin):
      return "<link rel=\"preconnect\" href=\"\(HTMLRenderer.escape(origin))\">"
    }
  }

  private static func apply(
    _ transform: AssetTransform,
    to bytes: [UInt8],
    asset: BuildAsset,
    toolchain: AssetToolchain,
    layout: OutputLayout
  ) throws -> [UInt8] {
    let tool: AssetTool?
    let arguments: (URL, URL) -> [String]
    let outputExtension: String
    switch transform {
    case .optimizeSVG:
      tool = toolchain.svg
      arguments = {
        ["--skip-system-fonts", "--preserve-text", "\($0.path())", "\($1.path())"]
      }
      outputExtension = "svg"
    case .resizeImage(let width, let format):
      guard width > 0 else { throw BuildError.invalidArtifactPath("image width \(width)") }
      tool = toolchain.image
      arguments = {
        ["thumbnail", "\($0.path())", "\($1.path())", "\(width)", "--height=2147483647"]
      }
      outputExtension = format.rawValue
    case .subsetFont(let characters):
      guard !characters.isEmpty else { throw BuildError.invalidArtifactPath("empty font subset") }
      tool = toolchain.font
      arguments = {
        ["\($0.path())", "--output-file=\($1.path())", "--text=\(characters)"]
      }
      outputExtension = asset.path.split(separator: ".").last.map(String.init) ?? "font"
    case .bundleScript:
      tool = toolchain.script
      arguments = { ["\($0.path())", "--bundle", "--minify", "--outfile=\($1.path())"] }
      outputExtension = "js"
    }
    guard let tool else { throw BuildError.missingAssetTool(transform.identifier) }
    return try run(
      tool,
      arguments: arguments,
      bytes: bytes,
      inputExtension: asset.path.split(separator: ".").last.map(String.init) ?? "input",
      outputExtension: outputExtension,
      transform: transform.identifier,
      layout: layout
    )
  }

  private static func recordedIdentifier(
    _ transform: AssetTransform,
    toolchain: AssetToolchain
  ) -> String {
    let tool =
      switch transform {
      case .optimizeSVG: toolchain.svg
      case .resizeImage: toolchain.image
      case .subsetFont: toolchain.font
      case .bundleScript: toolchain.script
      }
    return "\(transform.identifier)@\(tool?.expectedDigest.lowercased() ?? "missing")"
  }

  private static func run(
    _ tool: AssetTool,
    arguments: (URL, URL) -> [String],
    bytes: [UInt8],
    inputExtension: String,
    outputExtension: String,
    transform: String,
    layout: OutputLayout
  ) throws -> [UInt8] {
    let directory = layout.path(for: .temporary)
      .appendingPathComponent("assets", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    guard layout.contains(directory) else {
      throw BuildError.outputEscapesRobinRoot(directory.path())
    }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let stagedTool = directory.appendingPathComponent("tool")
    try FileManager.default.copyItem(at: tool.executable, to: stagedTool)
    let executableBytes = Array(try Data(contentsOf: stagedTool))
    guard ContentDigest.sha256(executableBytes) == tool.expectedDigest.lowercased() else {
      throw BuildError.assetToolDigestMismatch(tool.executable.path())
    }
    let cacheKey = ContentDigest.sha256(
      Array(
        "\(transform)\u{0}\(tool.expectedDigest.lowercased())\u{0}\(inputExtension)\u{0}\(outputExtension)\u{0}"
          .utf8
      ) + bytes)
    let cacheDirectory = layout.path(for: .cache)
      .appendingPathComponent("transforms", isDirectory: true)
      .appendingPathComponent(cacheKey, isDirectory: true)
    guard layout.contains(cacheDirectory) else {
      throw BuildError.outputEscapesRobinRoot(cacheDirectory.path())
    }
    let cachedOutput = cacheDirectory.appendingPathComponent("output")
    let cachedDigest = cacheDirectory.appendingPathComponent("sha256")
    let outputExists = FileManager.default.fileExists(atPath: cachedOutput.path())
    let digestExists = FileManager.default.fileExists(atPath: cachedDigest.path())
    if outputExists || digestExists {
      guard outputExists, digestExists else { throw BuildError.corruptedCacheEntry(cacheKey) }
      let cachedBytes = Array(try Data(contentsOf: cachedOutput))
      let expectedDigest = String(decoding: try Data(contentsOf: cachedDigest), as: UTF8.self)
      guard ContentDigest.sha256(cachedBytes) == expectedDigest else {
        throw BuildError.corruptedCacheEntry(cacheKey)
      }
      return cachedBytes
    }
    let input = directory.appendingPathComponent("input.\(inputExtension)")
    let output = directory.appendingPathComponent("output.\(outputExtension)")
    let diagnosticURL = directory.appendingPathComponent("diagnostic.txt")
    try Data(bytes).write(to: input, options: .atomic)
    _ = FileManager.default.createFile(atPath: diagnosticURL.path(), contents: nil)
    let diagnosticHandle = try FileHandle(forWritingTo: diagnosticURL)

    let process = Process()
    process.executableURL = stagedTool
    process.arguments = arguments(input, output)
    var environment = ProcessInfo.processInfo.environment
    environment["LC_ALL"] = "C"
    environment["TZ"] = "UTC"
    environment["SOURCE_DATE_EPOCH"] = "0"
    process.environment = environment
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = diagnosticHandle
    try process.run()
    process.waitUntilExit()
    try diagnosticHandle.close()
    let diagnostic = String(decoding: try Data(contentsOf: diagnosticURL), as: UTF8.self)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard process.terminationStatus == 0,
      FileManager.default.fileExists(atPath: output.path())
    else {
      throw BuildError.assetToolFailed(
        transform, status: process.terminationStatus, diagnostic: diagnostic)
    }
    let outputBytes = Array(try Data(contentsOf: output))
    try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    try Data(outputBytes).write(to: cachedOutput, options: .atomic)
    try Data(ContentDigest.sha256(outputBytes).utf8).write(to: cachedDigest, options: .atomic)
    return outputBytes
  }
}

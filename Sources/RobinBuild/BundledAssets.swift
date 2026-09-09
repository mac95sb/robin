import Foundation
@_spi(Rendering) import RobinHTML

/// Discovers public image and font resources packaged with an application target.
enum BundledAssets {
  private static let mediaTypes = [
    "avif": "image/avif",
    "ico": "image/x-icon",
    "jpeg": "image/jpeg",
    "jpg": "image/jpeg",
    "png": "image/png",
    "svg": "image/svg+xml",
    "webp": "image/webp",
    "woff": "font/woff",
    "woff2": "font/woff2",
  ]

  static func discover<Application: App>(for _: Application.Type) throws -> [BuildAsset] {
    var assets: [String: BuildAsset] = [:]
    for bundle in [applicationResourceBundle(for: Application.self)].compactMap({ $0 }) {
      guard let resourceURL = bundle.resourceURL,
        let files = try? FileManager.default.contentsOfDirectory(
          at: resourceURL, includingPropertiesForKeys: [.isRegularFileKey])
      else { continue }
      for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        let suffix = file.pathExtension.lowercased()
        guard let mediaType = mediaTypes[suffix],
          (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        else { continue }
        let reference = "/\(file.lastPathComponent)"
        guard assets[reference] == nil else { continue }
        assets[reference] = try BuildAsset(
          reference: reference,
          path: "assets/\(file.lastPathComponent)",
          bytes: Array(Data(contentsOf: file)),
          mediaType: mediaType)
      }
    }
    return assets.values.sorted { $0.reference < $1.reference }
  }

}

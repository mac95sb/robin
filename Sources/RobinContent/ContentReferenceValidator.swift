import Foundation

/// Validates local Markdown destinations against generated routes and assets.
public struct ContentReferenceValidator: Sendable {
  private let routes: Set<String>
  private let assets: Set<String>

  /// Creates a validator from the routes and assets emitted by a build.
  public init(routes: Set<String>, assets: Set<String>) {
    self.routes = Set(routes.map(Self.normalized))
    self.assets = Set(assets.map(Self.normalized))
  }

  /// Returns every invalid or missing local reference in source order.
  public func validate(
    _ references: [ContentReference],
    from sourceRoute: String = "/"
  ) -> [ContentDiagnostic] {
    references.compactMap { reference in
      let destination: String
      switch reference {
      case .link(let value), .asset(let value): destination = value
      }

      guard let path = Self.localPath(destination, relativeTo: sourceRoute) else {
        return Self.isAllowedExternal(destination) ? nil : .invalidReference(destination)
      }

      switch reference {
      case .link:
        return routes.contains(path) ? nil : .brokenLink(destination)
      case .asset:
        return assets.contains(path) ? nil : .missingAsset(destination)
      }
    }
  }

  private static func localPath(_ destination: String, relativeTo sourceRoute: String) -> String? {
    if destination.hasPrefix("#") { return normalized(sourceRoute) }
    guard let components = URLComponents(string: destination), components.scheme == nil,
      components.host == nil
    else { return nil }
    guard !components.path.isEmpty, !components.path.split(separator: "/").contains("..") else {
      return nil
    }

    if components.path.hasPrefix("/") { return normalized(components.path) }
    let directory =
      sourceRoute.hasSuffix("/")
      ? sourceRoute : (sourceRoute as NSString).deletingLastPathComponent + "/"
    return normalized(directory + components.path)
  }

  private static func isAllowedExternal(_ destination: String) -> Bool {
    guard let scheme = URLComponents(string: destination)?.scheme?.lowercased() else {
      return destination.hasPrefix("#")
    }
    return ["http", "https", "mailto", "tel"].contains(scheme)
  }

  private static func normalized(_ path: String) -> String {
    let path = path.hasPrefix("/") ? path : "/" + path
    return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
  }
}

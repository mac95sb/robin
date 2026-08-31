import Foundation

/// A client capability permitted to emit a Robin runtime module.
public enum RuntimeCapability: String, Equatable, Sendable {
  case browserAPI
  case clientNavigation
  case clientState
  case customCommand
  case liveUpdates
  case offline
  case programmaticMedia
  case semanticWidget
  case webAuthentication
}

/// One emitted client module recorded in a build manifest.
public struct RuntimeManifestEntry: Equatable, Sendable {
  public let path: String
  public let capability: RuntimeCapability
  public let owner: String
  public let reason: String
  public let fallback: String?
  public let requiresFallback: Bool

  public init(
    path: String,
    capability: RuntimeCapability,
    owner: String,
    reason: String,
    fallback: String? = nil,
    requiresFallback: Bool = false
  ) {
    self.path = path
    self.capability = capability
    self.owner = owner
    self.reason = reason
    self.fallback = fallback
    self.requiresFallback = requiresFallback
  }
}

/// Validates that every shipped JavaScript file is explained by the typed build manifest.
public enum RuntimeManifestValidation {
  public enum Violation: Equatable, Sendable {
    case undocumentedRuntime(path: String)
    case emptyOwner(path: String)
    case emptyReason(path: String)
    case missingFallback(path: String)
  }

  public static func validate(
    outputFiles: [String],
    entries: [RuntimeManifestEntry]
  ) -> [Violation] {
    var violations: [Violation] = outputFiles.filter { $0.hasSuffix(".js") }.compactMap { path in
      entries.contains(where: { $0.path == path }) ? nil : .undocumentedRuntime(path: path)
    }
    for entry in entries {
      if entry.owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        violations.append(.emptyOwner(path: entry.path))
      }
      if entry.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        violations.append(.emptyReason(path: entry.path))
      }
      if entry.requiresFallback,
        entry.fallback?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
      {
        violations.append(.missingFallback(path: entry.path))
      }
    }
    return violations
  }
}

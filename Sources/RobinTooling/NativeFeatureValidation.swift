import Foundation

/// Browser support and fallback evidence for a native web-platform feature.
public struct NativeFeatureRecord: Equatable, Sendable {
  public let feature: String
  public let supportedBrowserBaseline: String
  public let fallback: String

  public init(feature: String, supportedBrowserBaseline: String, fallback: String) {
    self.feature = feature
    self.supportedBrowserBaseline = supportedBrowserBaseline
    self.fallback = fallback
  }
}

/// Validates that every native feature records its supported baseline and graceful fallback.
public enum NativeFeatureValidation {
  public enum Violation: Equatable, Sendable {
    case missingBrowserBaseline(feature: String)
    case missingFallback(feature: String)
  }

  public static func validate(_ records: [NativeFeatureRecord]) -> [Violation] {
    records.flatMap { record in
      var violations: [Violation] = []
      if record.supportedBrowserBaseline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        violations.append(.missingBrowserBaseline(feature: record.feature))
      }
      if record.fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        violations.append(.missingFallback(feature: record.feature))
      }
      return violations
    }
  }
}

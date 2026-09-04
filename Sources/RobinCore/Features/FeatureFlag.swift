import Foundation

/// A typed, provider-neutral feature flag definition.
public struct FeatureFlag<Value: Equatable & Sendable>: Sendable {
  /// The provider-facing flag identifier.
  public let key: String
  /// The value used when no provider or override supplies one.
  public let defaultValue: Value
  /// The date after which the flag should be removed.
  public let removalDate: Date?
  /// The date a flag became permanently fixed to its default value.
  public let fixedValueSince: Date?

  /// Creates a typed feature flag.
  ///
  /// - Parameters:
  ///   - key: The provider-facing identifier.
  ///   - defaultValue: The deterministic fallback value.
  ///   - removalDate: An optional deadline for removing the flag.
  ///   - fixedValueSince: When a temporary flag stopped varying and should be removed.
  public init(
    _ key: String,
    default defaultValue: Value,
    removalDate: Date? = nil,
    fixedValueSince: Date? = nil
  ) {
    self.key = key
    self.defaultValue = defaultValue
    self.removalDate = removalDate
    self.fixedValueSince = fixedValueSince
  }
}

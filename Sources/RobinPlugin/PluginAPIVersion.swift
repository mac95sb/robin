/// A positive version of Robin's plugin contract.
public struct PluginAPIVersion: Comparable, Hashable, Sendable {
  /// The plugin API implemented by this Robin release.
  public static let current = PluginAPIVersion(1)

  /// The positive numeric version.
  public let value: UInt

  /// Creates a plugin API version.
  ///
  /// - Parameter value: A positive version number.
  public init(_ value: UInt) {
    precondition(value > 0, "A plugin API version must be positive.")
    self.value = value
  }

  /// Orders plugin API versions by their numeric value.
  public static func < (lhs: Self, rhs: Self) -> Bool { lhs.value < rhs.value }
}

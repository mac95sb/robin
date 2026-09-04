/// A Robin extension with an explicitly checked plugin API compatibility range.
public protocol Plugin: Sendable {
  /// The plugin API versions supported by this extension.
  static var supportedPluginAPIVersions: ClosedRange<PluginAPIVersion> { get }
}

extension Plugin {
  /// Supports the current plugin API version only.
  public static var supportedPluginAPIVersions: ClosedRange<PluginAPIVersion> {
    .current ... .current
  }

  /// Verifies that the extension supports the host's plugin API version.
  ///
  /// - Parameter version: The host plugin API version.
  /// - Throws: ``PluginCompatibilityError`` when the version falls outside the supported range.
  public static func validateCompatibility(with version: PluginAPIVersion = .current) throws {
    guard supportedPluginAPIVersions.contains(version) else {
      throw PluginCompatibilityError(
        plugin: String(reflecting: Self.self),
        supported: supportedPluginAPIVersions,
        host: version
      )
    }
  }
}

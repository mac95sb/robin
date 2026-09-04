import RobinPlugin
import Testing

@Suite("Plugin compatibility")
struct PluginCompatibilityTests {
  @Test func acceptsTheCurrentPluginAPI() throws {
    try CurrentPlugin.validateCompatibility()
  }

  @Test func rejectsAnUnsupportedPluginAPI() {
    #expect(throws: PluginCompatibilityError.self) {
      try LegacyPlugin.validateCompatibility()
    }
  }
}

private struct CurrentPlugin: Plugin {}

private struct LegacyPlugin: Plugin {
  static let supportedPluginAPIVersions = PluginAPIVersion(2)...PluginAPIVersion(3)
}

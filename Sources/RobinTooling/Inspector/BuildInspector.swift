import RobinBuild

package struct BuildInspectorEntry: Equatable, Sendable {
  package let path: String
  package let lowering: String
  package let selectedBy: String
}

package struct BuildInspector {
  package static func interactions(in manifest: BuildManifest) -> [BuildInspectorEntry] {
    manifest.artifacts.compactMap { artifact -> BuildInspectorEntry? in
      guard let origin = artifact.scriptOrigin else { return nil }
      return switch origin {
      case .robinCustomCommand(let command, let selectedBy):
        BuildInspectorEntry(
          path: artifact.path,
          lowering: "custom command: \(command)",
          selectedBy: selectedBy
        )
      case .robinDirectCapability(let capability, let selectedBy):
        BuildInspectorEntry(
          path: artifact.path,
          lowering: "direct capability: \(capability.rawValue)",
          selectedBy: selectedBy
        )
      case .application(let exception):
        BuildInspectorEntry(
          path: artifact.path,
          lowering: "application script",
          selectedBy: exception
        )
      }
    }
  }
}

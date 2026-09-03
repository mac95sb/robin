import Foundation
import RobinBuild
import RobinCore
import RobinHTML

extension RobinApplication {
  /// Builds or serves an API or server-rendered application.
  ///
  /// - Parameter application: The application configuration to build or serve.
  /// - Throws: A build, startup, or server runtime error.
  public static func run<Application: App>(_ application: Application) async throws {
    if ProcessInfo.processInfo.environment["ROBIN_BUILD"] == "1" {
      let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      let executable = URL(fileURLWithPath: CommandLine.arguments[0])
      let artifact = try BuildArtifact(
        kind: .executable,
        path: executable.lastPathComponent,
        bytes: Array(try Data(contentsOf: executable))
      )
      _ = try await BuildPipeline.build(
        application,
        configuration: .init(executableArtifacts: [artifact]),
        in: OutputLayout(projectRoot: root)
      )
      return
    }
    let runtime = try await ServerRuntime.start(application)
    try await runtime.run()
  }
}

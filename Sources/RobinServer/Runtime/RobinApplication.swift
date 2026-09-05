import Foundation
import RobinBuild
import RobinCore
import RobinHTML

extension RobinApplication {
  /// Builds or serves an API or server-rendered application.
  ///
  /// - Parameters:
  ///   - application: The application configuration to build or serve.
  ///   - assets: Typed assets to build or serve with the application.
  ///   - address: Listener address used by the persistent server transport.
  ///   - middleware: Middleware applied in array order.
  ///   - onShutdown: Releases application-owned services after the runtime stops.
  /// - Throws: A build, startup, or server runtime error.
  public static func run<Application: App>(
    _ application: Application,
    assets: [BuildAsset] = [],
    address: ServerAddress = .init(host: "127.0.0.1", port: 8080),
    middleware: [Middleware] = [],
    onShutdown: @escaping @Sendable () async throws -> Void = {}
  ) async throws {
    let middleware = assets.isEmpty ? middleware : [.clientAssets(assets)] + middleware
    do {
      if ProcessInfo.processInfo.environment["ROBIN_BUILD"] == "1" {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let executable = URL(fileURLWithPath: CommandLine.arguments[0])
        let artifact = try BuildArtifact(
          kind: .executable,
          path: executable.lastPathComponent,
          bytes: Array(try Data(contentsOf: executable))
        )
        #if arch(arm64)
          let architecture = DeploymentRuntime.Architecture.arm64
        #elseif arch(x86_64)
          let architecture = DeploymentRuntime.Architecture.x64
        #else
          throw BuildError.invalidRuntimeConfiguration("persistent deployment architecture")
        #endif
        _ = try await BuildPipeline.build(
          application,
          configuration: .init(
            runtimeArtifacts: [artifact],
            assets: assets,
            runtimes: [
              try DeploymentRuntime(
                .persistentHTTP,
                artifact: artifact.path,
                architecture: architecture
              )
            ]
          ),
          in: OutputLayout(projectRoot: root)
        )
      } else if ProcessInfo.processInfo.environment["AWS_LAMBDA_RUNTIME_API"] != nil {
        let runtime = try InvocationRuntime(
          application,
          codec: AWSLambdaHTTPEventCodec(),
          middleware: middleware,
          transportCapabilities: .lambda
        )
        try await runtime.run(using: AWSLambdaRuntimeAPIChannel())
      } else {
        let runtime = try await ServerRuntime.start(
          application, host: address.host, port: address.port, middleware: middleware)
        try await runtime.run()
      }
    } catch {
      try? await onShutdown()
      throw error
    }
    try await onShutdown()
  }
}

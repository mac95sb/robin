import Foundation
import RobinCore
import RobinHTML

extension RobinApplication {
  /// Builds and materializes a static application beneath `.robin`.
  ///
  /// - Parameters:
  ///   - application: The static application configuration to build.
  ///   - assets: Typed browser assets to include in the static output.
  /// - Throws: A render, build, or filesystem error.
  public static func run<Application: App>(_ application: Application, assets: [BuildAsset] = [])
    throws
  where Application.RouteRegistration == EmptyRoutes {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let optimizesAssets = ProcessInfo.processInfo.environment["ROBIN_NO_OPTIM"] != "1"
    _ = try BuildPipeline.build(
      application,
      configuration: .init(
        cssOutputMode: optimizesAssets ? .production : .development,
        assets: assets,
        optimizesAssets: optimizesAssets),
      in: OutputLayout(projectRoot: root))
  }
}

import Foundation
import RobinCore
import RobinHTML

extension RobinApplication {
  /// Builds and materializes a static application beneath `.robin`.
  ///
  /// - Parameter application: The static application configuration to build.
  /// - Throws: A render, build, or filesystem error.
  public static func run<Application: App>(_ application: Application) throws
  where Application.RouteRegistration == EmptyRoutes {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    _ = try BuildPipeline.build(application, in: OutputLayout(projectRoot: root))
  }
}

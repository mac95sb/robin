import Foundation
import RobinBuild
import RobinCore
import RobinHTML

@main
struct Documentation: App {
  var metadata: Metadata {
    Metadata(
      site: "Robin", description: "Build static sites, server applications, and APIs in Swift.")
  }

  var pages: some Pages { HomePage() }

  static func main() throws {
    _ = try BuildPipeline.build(
      Self(), configuration: .init(cdnBaseURL: URL(string: "https://mac95sb.github.io/robin")!),
      in: OutputLayout(projectRoot: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)))
  }
}

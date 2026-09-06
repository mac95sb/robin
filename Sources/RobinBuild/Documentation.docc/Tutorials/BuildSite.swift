import Foundation
import RobinBuild
import RobinCore
import RobinHTML

struct HomePage: Page {
  let path = "/"
  var body: ComponentContent { Main { Heading { "Hello, Robin" } } }
}

struct Site: App {
  var metadata: Metadata { Metadata(title: "My site", language: "en") }
  var pages: some Pages { HomePage() }
}

let layout = OutputLayout(
  projectRoot: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
)
let result = try BuildPipeline.build(Site(), in: layout)
assert(!result.manifest.artifacts.isEmpty)

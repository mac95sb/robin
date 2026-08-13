import Foundation
import Testing

@testable import RobinValidation

@Suite("Robin build-output layout and path containment")
struct OutputLayoutTests {
  @Test func everyRobinArtifactIsContainedAndTraversalIsRejected() throws {
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let layout = OutputLayout(projectRoot: temporary)
    defer { try? FileManager.default.removeItem(at: temporary) }

    #expect(
      layout.robinRoot == temporary.appendingPathComponent(".robin", isDirectory: true)
    )
    for artifact in RobinArtifact.allCases {
      let path = layout.path(for: artifact)
      #expect(layout.contains(path))
      try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
      try Data(artifact.rawValue.utf8).write(to: path.appendingPathComponent("probe"))
    }
    #expect(layout.contains(temporary.appendingPathComponent("outside")) == false)
    #expect(layout.contains(layout.robinRoot.appendingPathComponent("../outside")) == false)
  }
}

import Foundation
import Testing

@testable import RobinCore

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
    let outside = temporary.appendingPathComponent("outside", isDirectory: true)
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    let link = layout.robinRoot.appendingPathComponent("escape")
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
    #expect(layout.contains(temporary.appendingPathComponent("outside")) == false)
    #expect(layout.contains(layout.robinRoot.appendingPathComponent("../outside")) == false)
    #expect(layout.contains(link.appendingPathComponent("probe")) == false)

    try FileManager.default.removeItem(at: layout.robinRoot)
    try FileManager.default.createSymbolicLink(at: layout.robinRoot, withDestinationURL: outside)
    #expect(layout.contains(layout.path(for: .build)) == false)
  }
}

import Foundation
import RobinBuild
import Testing

@Test func browserControlsValidateIdentifiersAndEmitDistinctAssets() throws {
  #expect(throws: BuildError.self) { try TabsClientModule(navigationID: " ", label: "Files") }
  let first = try TabsClientModule(navigationID: "first", label: "Files").asset()
  let second = try TabsClientModule(navigationID: "second", label: "Files").asset()
  #expect(first.reference != second.reference)
  #expect(
    first.bytes == (try TabsClientModule(navigationID: "first", label: "Files").asset()).bytes)
}

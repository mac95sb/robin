import Foundation
import Testing

@Suite("Public API design")
struct APIDesignTests {
  @Test func publicEnumsModelCasesRatherThanNamespaces() throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
    let sources = root.appendingPathComponent("Sources")
    let files = try #require(
      FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)?
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == "swift" }
    )
    let declaration = try NSRegularExpression(
      pattern: #"(?ms)^public enum ([A-Za-z][A-Za-z0-9_]*)[^\{]*\{(.*?)^\}"#
    )

    for file in files {
      let source = try String(contentsOf: file, encoding: .utf8)
      let range = NSRange(source.startIndex..., in: source)
      for match in declaration.matches(in: source, range: range) {
        let bodyRange = try #require(Range(match.range(at: 2), in: source))
        let body = source[bodyRange]
        #expect(
          body.split(separator: "\n").contains { $0.hasPrefix("  case ") },
          "\(file.lastPathComponent) contains a public case-less enum namespace."
        )
      }
    }
  }
}

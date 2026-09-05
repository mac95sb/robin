import Foundation
import RobinBuild
import RobinCache
import RobinContent
import RobinCore
import RobinData
@_spi(Rendering) import RobinHTML
import RobinRouting
import RobinServer
@_spi(Rendering) import RobinStyle
import Testing

@Suite(.serialized)
struct ReleaseBenchmarks {
  @Test(
    .enabled(if: ProcessInfo.processInfo.environment["ROBIN_BENCHMARKS"] == "1"),
    arguments: [
      "render", "escape", "styles", "routes", "form", "query", "cache", "markdown", "graph",
    ])
  func measuresRepresentativeOperations(_ operation: String) async throws {
    #if DEBUG
      Issue.record("Run benchmarks with mise run benchmark (release configuration).")
      return
    #else
      let route = RouteDefinition.path(["items"], parameter: .integer("id"))
      let text = String(repeating: "Swift <&> Robin ", count: 50)
      let cache = MemoryCacheStore(capacity: 1)
      let now = Date()
      await cache.store(
        .init(
          data: Data(text.utf8), expiresAt: now.addingTimeInterval(60),
          staleUntil: now.addingTimeInterval(120), entityTag: "fixture", lastModified: now, tags: []
        ),
        for: "fixture")
      let artifacts = try (0..<20).map {
        try BuildArtifact(kind: .staticFile, path: "\($0).html", bytes: Array(text.utf8))
      }
      let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
        UUID().uuidString)
      defer { try? FileManager.default.removeItem(at: directory) }
      let layout = OutputLayout(projectRoot: directory)
      let graph = try ArtifactGraph(artifacts)
      _ = try graph.materialize(in: layout)
      var samples: [Double] = []
      var checksum = 0
      for _ in 0..<5 {
        let elapsed = try await ContinuousClock().measure {
          for iteration in 0..<100 {
            switch operation {
            case "render": checksum += try HTMLRenderer.render(Text { text }).utf8.count
            case "escape": checksum += HTMLRenderer.escape(text).utf8.count
            case "styles":
              let component = Text { text }.padding(.md)
              checksum += try StyleCompiler.compile(
                .fragment(component.body.nodes), theme: .default, mode: .production
              ).css.utf8.count
            case "routes": checksum += route.match(route.url(for: iteration)) ?? 0
            case "form":
              let request = Request(
                .init(
                  method: .post, scheme: nil, authority: nil, path: "/",
                  headerFields: [.contentType: "application/x-www-form-urlencoded"]),
                body: Array("name=Swift+Robin&value=42".utf8))
              checksum += request.formValue(named: "name")?.utf8.count ?? 0
            case "query":
              let statement: SQLStatement = "SELECT id FROM items WHERE id = \(iteration)"
              checksum += statement.render(for: .postgres).sql.utf8.count
            case "cache": checksum += await cache.record(for: "fixture", at: now)?.data.count ?? 0
            case "markdown":
              checksum += try HTMLRenderer.render(
                MarkdownContentParser.parse("# Robin\n\n\(text)", allowedEmbedHosts: [])
              ).utf8.count
            default: checksum += try graph.materialize(in: layout).artifacts.count
            }
          }
        }
        samples.append(
          Double(elapsed.components.seconds) * 1_000
            + Double(elapsed.components.attoseconds) / 1e15)
      }
      let median = samples.sorted()[2]
      print("benchmark \(operation): median \(median) ms / 100 operations; checksum \(checksum)")
      #expect(checksum > 0)
      // A generous hang/regression guard; recorded medians are the initial platform baselines.
      #expect(median < 5_000)
    #endif
  }
}

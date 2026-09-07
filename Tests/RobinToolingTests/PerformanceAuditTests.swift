import Foundation
import Testing

@testable import RobinTooling

@Suite("Performance audits")
struct PerformanceAuditTests {
  @Test func offlineSizesAndMissingOutputAreExplicit() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    #expect(BuildPerformanceAudit.audit(at: root).first?.code == "performance-skipped")
    let build = root.appendingPathComponent(".robin/build")
    try FileManager.default.createDirectory(at: build, withIntermediateDirectories: true)
    try Data("hello".utf8).write(to: build.appendingPathComponent("index.html"))
    let manifest =
      #"{"artifacts":[{"kind":"staticFile","path":"index.html","digest":"test","byteCount":999,"dependencies":[],"transforms":[],"mediaType":"text/html"}]}"#
    try Data(manifest.utf8).write(to: build.appendingPathComponent("manifest.json"))
    let results = BuildPerformanceAudit.audit(at: root)
    #expect(results.first?.measurement?.value == 5)
    #expect(results.first?.measurement?.unit == "bytes")
    let escaping = manifest.replacingOccurrences(of: "index.html", with: "../../outside.html")
    try Data(escaping.utf8).write(to: build.appendingPathComponent("manifest.json"))
    #expect(BuildPerformanceAudit.audit(at: root).first?.severity == .error)
  }

  @Test func pageSpeedPreservesUnitsAndDoesNotInventMissingMetrics() throws {
    let response =
      #"{"lighthouseResult":{"categories":{"performance":{"score":0.92}},"audits":{"largest-contentful-paint":{"numericValue":1200},"cumulative-layout-shift":{"numericValue":0.01},"unused-css":{"title":"Reduce unused CSS","score":0,"scoreDisplayMode":"binary"}}}}"#
    let results = try PageSpeedAudit.diagnostics(from: Data(response.utf8), strategy: .mobile)
    #expect(results.first?.measurement?.value == 92)
    #expect(
      results.contains { $0.code == "largest-contentful-paint" && $0.measurement?.value == 1200 })
    #expect(results.filter { $0.code == "pagespeed-metric-unavailable" }.count == 3)
    #expect(results.contains { $0.code == "pagespeed-unused-css" && $0.severity == .warning })
    let failed = #"{"lighthouseResult":{"runtimeError":{"code":"NO_FCP"},"audits":{}}}"#
    #expect(
      try PageSpeedAudit.diagnostics(from: Data(failed.utf8), strategy: .desktop).first?.severity
        == .error)
    let request = try PageSpeedAudit.request(
      url: "https://example.com/?a=1&b=2", strategy: .desktop, key: "fixture")
    let query = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?
      .queryItems
    #expect(query?.first { $0.name == "url" }?.value == "https://example.com/?a=1&b=2")
    #expect(throws: (any Error).self) {
      try PageSpeedAudit.request(
        url: "https://user:password@example.com", strategy: .mobile, key: nil)
    }
    let encoded = try JSONEncoder().encode(results)
    #expect(try JSONDecoder().decode([ToolDiagnostic].self, from: encoded) == results)
  }
}

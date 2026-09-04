import Foundation
import HTTPTypes
import RobinBuild
import RobinCore
import RobinHTML
import RobinServer
import RobinStyle
import Testing

@testable import RobinTesting

@Suite("Robin testing tools")
struct RobinTestingTests {
  @Test func snapshotsRecordMatchAndReportDifferences() throws {
    let layout = OutputLayout(projectRoot: temporaryDirectory())
    #expect(throws: SnapshotError.missing("home")) {
      try SnapshotTesting.verify("first", named: "home", as: .html, in: layout)
    }
    try SnapshotTesting.verify("first", named: "home", as: .html, in: layout, recording: true)
    try SnapshotTesting.verify("first", named: "home", as: .html, in: layout)
    #expect(throws: SnapshotError.mismatch("home")) {
      try SnapshotTesting.verify("second", named: "home", as: .html, in: layout)
    }
  }

  @Test func routeClientUsesTheTransportNeutralResponder() async throws {
    let client = try RouteTestClient(TestApplication())
    let response = await client.response(
      to: Request(HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/")))
    #expect(response.head.status == .ok)
  }

  @Test func accessibilityAuditFindsHeadingSkipsAndUnnamedButtons() {
    let findings = AccessibilityAudit.audit(
      Stack {
        Heading(.one) { "First" }
        Heading(.three) { "Third" }
        Button {}
      })
    #expect(findings.map(\.code) == ["heading-level-skip", "button-name"])
  }

  @Test func previewMacroAndDashboardStayUnderRobinPreviewOutput() throws {
    let preview = #Preview(
      "Greeting",
      category: "Basics",
      state: "Loaded",
      documentation: "A localized greeting.",
      checks: [.init("content") {}]
    ) { Text { "Hello" } }
    let layout = OutputLayout(projectRoot: temporaryDirectory())
    let output = try PreviewDashboard.generate([preview], in: layout)
    #expect(layout.contains(output))
    #expect(output.path.contains("/.robin/preview/"))
    let html = try String(contentsOf: output, encoding: .utf8)
    #expect(html.contains("Greeting"))
    #expect(html.contains("data:text/html;base64"))
    #expect(html.contains("Accessibility"))
    #expect(html.contains("content: passed"))
    #expect(html.contains("data-scheme=\"dark\""))
    #expect(html.contains("data-state=\"Loaded\""))
    #expect(try preview.render(locale: "fr").contains("<html lang=\"fr\">"))

    let result = try BuildPipeline.build(TestApplication(), in: layout)
    #expect(!result.manifest.artifacts.contains { $0.path.contains("preview") })
  }

  @Test func webdriverSessionIdentifierUsesTheW3CResponseEnvelope() {
    #expect(
      BrowserSession.sessionIdentifier(in: ["value": ["sessionId": "session-1"]])
        == "session-1")
    #expect(BrowserSession.sessionIdentifier(in: ["sessionId": "legacy"]) == nil)
  }

  @Test func browserSessionsRejectNonLoopbackDriversBeforeNetworking() async {
    let profile = BrowserTestProfile(browser: .chrome)
    #expect(!profile.javaScriptEnabled)
    #expect(BrowserSession.isValidElementIdentifier("submit-button"))
    #expect(!BrowserSession.isValidElementIdentifier("button > script"))
    await #expect(throws: BrowserSessionError.self) {
      try await BrowserSession.start(
        at: URL(string: "http://example.com:4444")!,
        profile: profile
      )
    }
    await #expect(
      throws: BrowserSessionError.unsupportedProfile(
        "Safari WebDriver cannot guarantee a JavaScript-disabled session."
      )
    ) {
      try await BrowserSession.start(
        at: URL(string: "http://localhost:4444")!,
        profile: .init(browser: .safari)
      )
    }
  }

  private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }
}

private struct TestApplication: App {
  var pages: some Pages { HomePage() }
}

private struct HomePage: Page {
  let path = "/"
  var body: ComponentContent { Text { "Home" } }
}

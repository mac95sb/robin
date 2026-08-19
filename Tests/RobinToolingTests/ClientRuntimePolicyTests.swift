import RobinCore
import Testing

@testable import RobinTooling

@Suite("Client runtime policy")
struct ClientRuntimePolicyTests {
  @Test func staticApplicationWithoutClientNavigationRejectsTheRuntimeChunk() {
    #expect(
      throws: ClientRuntimePolicy.Violation.unexpectedClientRuntimeChunk(
        path: "/dist/robin-client-navigation.js")
    ) {
      try ClientRuntimePolicy.validate(
        mode: .static,
        clientNavigationEnabled: false,
        outputFiles: ["/dist/index.html", "/dist/robin-client-navigation.js"]
      )
    }
  }

  @Test func staticApplicationWithoutClientNavigationAllowsOtherOutput() throws {
    try ClientRuntimePolicy.validate(
      mode: .static,
      clientNavigationEnabled: false,
      outputFiles: ["/dist/index.html", "/dist/app.css"]
    )
  }

  @Test func staticApplicationWithClientNavigationEnabledAllowsTheRuntimeChunk() throws {
    try ClientRuntimePolicy.validate(
      mode: .static,
      clientNavigationEnabled: true,
      outputFiles: ["/dist/index.html", "/dist/robin-client-navigation.js"]
    )
  }

  @Test func nonStaticApplicationsAreNeverChecked() throws {
    try ClientRuntimePolicy.validate(
      mode: .ssr,
      clientNavigationEnabled: false,
      outputFiles: ["/dist/robin-client-navigation.js"]
    )
  }
}

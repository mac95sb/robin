import Testing

@testable import RobinTooling

@Suite("Runtime manifest validation")
struct RuntimeManifestValidationTests {
  @Test func everyRuntimeChunkIsCapabilityScopedExplainedAndOwned() {
    let entries = [
      RuntimeManifestEntry(
        path: "/dist/passkeys.js",
        capability: .webAuthentication,
        owner: "Passkey ceremony",
        reason: "WebAuthn has no declarative HTML entry point",
        fallback: "Offer an authenticated recovery route",
        requiresFallback: true
      )
    ]

    #expect(
      RuntimeManifestValidation.validate(
        outputFiles: ["/dist/index.html", "/dist/passkeys.js"],
        entries: entries
      ).isEmpty
    )
  }

  @Test func diagnosesUnexplainedRuntimeAndMissingFallback() {
    let entries = [
      RuntimeManifestEntry(
        path: "/dist/live.js",
        capability: .liveUpdates,
        owner: "",
        reason: "",
        requiresFallback: true
      )
    ]

    #expect(
      RuntimeManifestValidation.validate(
        outputFiles: ["/dist/live.js", "/dist/raw.js"],
        entries: entries
      ) == [
        .undocumentedRuntime(path: "/dist/raw.js"),
        .emptyOwner(path: "/dist/live.js"),
        .emptyReason(path: "/dist/live.js"),
        .missingFallback(path: "/dist/live.js"),
      ]
    )
  }
}

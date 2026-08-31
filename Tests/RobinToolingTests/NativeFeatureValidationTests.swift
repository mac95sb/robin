import Testing

@testable import RobinTooling

@Suite("Native feature validation")
struct NativeFeatureValidationTests {
  @Test func recordsBrowserBaselineAndGracefulFallback() {
    let records = [
      NativeFeatureRecord(
        feature: "Cross-document View Transitions",
        supportedBrowserBaseline: "Project browser matrix",
        fallback: "Ordinary document navigation"
      )
    ]

    #expect(NativeFeatureValidation.validate(records).isEmpty)
  }

  @Test func diagnosesMissingCompatibilityEvidence() {
    let records = [
      NativeFeatureRecord(feature: "Popover", supportedBrowserBaseline: "", fallback: "")
    ]

    #expect(
      NativeFeatureValidation.validate(records) == [
        .missingBrowserBaseline(feature: "Popover"),
        .missingFallback(feature: "Popover"),
      ]
    )
  }
}

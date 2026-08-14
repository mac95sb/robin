import Testing

@testable import RobinValidation

@Suite("Macro-generated field names")
struct GeneratedFieldNameTests {
  @Test func macroProducesStableNames() {
    #expect(#generatedFieldName("email") == "form.email")
    #expect(#generatedFieldName("displayName") == "form.displayName")
  }
}

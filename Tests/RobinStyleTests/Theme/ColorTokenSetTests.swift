import RobinStyle
import Testing

@ColorTokenSet
private enum BrandColor: String, CaseIterable, Sendable {
  case logo
  case highlight
}

@Suite("Color token sets")
struct ColorTokenSetTests {
  @Test func macroGeneratesStableTypedIdentitiesAndCompleteRegistration() throws {
    let registration: [BrandColor: Color] = [
      .logo: .oklch(0.5, 0.1, 30),
      .highlight: .oklch(0.7, 0.2, 100),
    ]
    let values = try BrandColor.register(registration)

    #expect(values[BrandColor.logo.colorToken] != nil)
    #expect(BrandColor.logo.colorToken.rawValue.hasSuffix("BrandColor.logo"))
  }

  @Test func registrationDiagnosesMissingTokens() {
    #expect(throws: ColorTokenSetError.missingTokens(["highlight"])) {
      let registration: [BrandColor: Color] = [
        .logo: .oklch(0.5, 0.1, 30)
      ]
      _ = try BrandColor.register(registration)
    }
  }
}

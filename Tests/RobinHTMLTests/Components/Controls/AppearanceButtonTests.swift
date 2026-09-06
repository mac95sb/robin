import RobinHTML
import Testing

@Test func appearanceButtonsExposeTheirPreferenceAndPressedState() throws {
  let system = try HTMLRenderer.render(
    AppearanceButton(.system, accessibilityLabel: "System") { "Auto" })
  let dark = try HTMLRenderer.render(
    AppearanceButton(.dark, accessibilityLabel: "Dark") { "Night" })
  #expect(system.contains("aria-pressed=\"true\""))
  #expect(dark.contains("aria-pressed=\"false\""))
  #expect(dark.contains("data-robin-appearance-choice=\"dark\""))
  #expect(dark.contains("type=\"button\""))
  #expect(dark.contains("aria-label=\"Dark\""))
}

import RobinHTML
import RobinRuntime
import Testing

@Test func appearanceButtonsExposeTheirPreferenceAndPressedState() throws {
  struct Preferences: AppearancePreferences {
    var appearance: AppearanceButton.Preference = .system
  }
  let preferences = Local("preferences", default: Preferences())
  let system = try HTMLRenderer.render(
    AppearanceButton(
      .system, preferences: preferences.binding, accessibilityLabel: "System"
    ) { "Auto" })
  let dark = try HTMLRenderer.render(
    AppearanceButton(
      .dark, preferences: preferences.binding, accessibilityLabel: "Dark"
    ) { "Night" })
  #expect(system.contains("aria-pressed=\"true\""))
  #expect(dark.contains("aria-pressed=\"false\""))
  #expect(dark.contains("data-robin-appearance-choice=\"dark\""))
  #expect(dark.contains("type=\"button\""))
  #expect(dark.contains("aria-label=\"Dark\""))
  #expect(dark.contains("data-robin-action"))
  #expect(dark.contains("preferences"))

  let combined = try HTMLRenderer.render(
    Stack {
      AppearanceButton(
        .system, preferences: preferences.binding, accessibilityLabel: "System"
      ) { "Auto" }
      AppearanceButton(
        .dark, preferences: preferences.binding, accessibilityLabel: "Dark"
      ) { "Night" }
    })
  #expect(combined.contains("&quot;s0&quot;"))
  #expect(!combined.contains("&quot;s1&quot;"))
}

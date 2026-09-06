import RobinHTML
import Testing

@Test func appearancePickerRendersNamedNativeChoices() throws {
  let html = try HTMLRenderer.render(AppearancePicker())
  #expect(html.contains("<select aria-label=\"Appearance\" data-robin-appearance-picker>"))
  for value in ["system", "light", "dark"] {
    #expect(html.contains("value=\"\(value)\""))
  }
}

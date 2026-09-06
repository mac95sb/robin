import RobinHTML
import Testing

@Test func languagePickerSelectsAndEscapesTheCurrentLanguage() throws {
  let picker = LanguagePicker(
    languages: [
      .init(code: "en", name: "English"), .init(code: "fr", name: "Français & français"),
    ],
    current: "fr")
  let html = try HTMLRenderer.render(picker)
  #expect(html.contains("<option selected value=\"fr\">Français &amp; français</option>"))
  #expect(html.contains("aria-label=\"Language\""))
}

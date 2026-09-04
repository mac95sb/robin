import RobinHTML
import RobinLucide
import Testing

@Suite("Lucide icons")
struct IconTests {
  @Test func rendersGeneratedVectorData() throws {
    let html = try HTMLRenderer.render(Icon(.activity))

    #expect(html.contains(#"aria-hidden="true""#))
    #expect(html.contains(#"viewBox="0 0 24 24""#))
    #expect(
      html.contains(
        #"<path d="M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2"></path>"#
      ))
  }

  @Test func labelsMeaningfulIcons() throws {
    let html = try HTMLRenderer.render(Icon(.notebookPen, size: 20, accessibilityLabel: "Notes"))

    #expect(html.contains(#"aria-label="Notes""#))
    #expect(html.contains(#"height="20""#))
    #expect(html.contains(#"role="img""#))
    #expect(!html.contains("aria-hidden"))
  }
}

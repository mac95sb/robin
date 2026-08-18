import RobinHTML
import Testing

@Suite("Disclosure")
struct DisclosureTests {
  @Test func closedDisclosureOmitsOpenAttribute() throws {
    let disclosure = try HTMLRenderer.render(
      Disclosure {
        "More info"
      } content: {
        Text { "Detail" }
      }
    )

    #expect(disclosure == "<details><summary>More info</summary><p>Detail</p></details>")
  }

  @Test func openDisclosureEmitsBareOpenAttribute() throws {
    let disclosure = try HTMLRenderer.render(
      Disclosure(open: true) {
        "More info"
      } content: {
        Text { "Detail" }
      }
    )

    #expect(disclosure == "<details open><summary>More info</summary><p>Detail</p></details>")
  }
}

import RobinHTML
import Testing

@Suite("Footer")
struct FooterTests {
  @Test func footerLowersToFooterLandmark() throws {
    let footer = try HTMLRenderer.render(Footer(id: "bottom") { Text { "Copyright" } })

    #expect(footer == #"<footer id="bottom"><p>Copyright</p></footer>"#)
  }
}

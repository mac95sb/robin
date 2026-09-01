import RobinHTML
import Testing

@Suite("Image")
struct ImageTests {
  @Test func imageLowersToVoidImgElement() throws {
    let image = try HTMLRenderer.render(
      Image(source: "/logo.png", alternateText: "Robin logo")
    )

    #expect(image == #"<img alt="Robin logo" src="/logo.png">"#)
  }
}

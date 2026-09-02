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

  @Test func rendersResponsiveSourcesInWidthOrder() throws {
    let image = try HTMLRenderer.render(
      Image(
        source: "/hero.jpg",
        alternateText: "Landscape",
        variants: [
          .init("/hero-large.webp", width: 1280),
          .init("/hero-small.webp", width: 640),
        ],
        sizes: "(min-width: 60rem) 50vw, 100vw"
      ))

    #expect(
      image
        == "<img alt=\"Landscape\" sizes=\"(min-width: 60rem) 50vw, 100vw\" src=\"/hero.jpg\" srcset=\"/hero-small.webp 640w, /hero-large.webp 1280w\">"
    )
  }

  @Test func rejectsNonpositiveResponsiveWidths() {
    #expect(throws: RenderDiagnostic.invalidResponsiveImageWidth(0)) {
      try HTMLRenderer.render(
        Image(
          source: "/hero.jpg",
          alternateText: "Landscape",
          variants: [.init("/hero.webp", width: 0)]
        ))
    }
  }
}

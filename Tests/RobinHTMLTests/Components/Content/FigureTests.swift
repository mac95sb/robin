import RobinHTML
import Testing

@Suite("Figure")
struct FigureTests {
  @Test func figureComposesImageAndCaption() throws {
    let figure = try HTMLRenderer.render(
      Figure {
        Image(source: "/chart.png", alternateText: "Growth chart")
        FigureCaption { "Quarterly growth" }
      }
    )

    #expect(
      figure
        == #"<figure><img alt="Growth chart" src="/chart.png"><figcaption>Quarterly growth</figcaption></figure>"#
    )
  }
}

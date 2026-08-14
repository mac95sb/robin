import Testing

@_spi(Rendering) @testable import RobinHTML

@Suite("View builder")
struct ViewBuilderTests {
  @Test func builderLowersStringExpressionsToTextNodes() {
    let content = ViewBuilder.buildExpression("Robin")

    #expect(content.nodes == [.text("Robin")])
  }
}

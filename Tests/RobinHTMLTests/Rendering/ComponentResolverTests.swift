import Testing

@_spi(Rendering) @testable import RobinHTML

private struct ConditionalComponent: Component {
  let includeSecond: Bool

  var body: ComponentContent {
    Leaf(value: "first")
    if includeSecond {
      Leaf(value: "second")
    }
    for value in ["third", "fourth"] {
      Leaf(value: value)
    }
  }
}

private struct Leaf: Component {
  let value: String

  var body: ComponentContent {
    ComponentContent(nodes: [.text(value)])
  }
}

@Suite("Component resolution")
struct ComponentResolverTests {
  @Test func builderSupportsNativeControlFlow() {
    let resolved = ComponentResolver.resolve(ConditionalComponent(includeSecond: true))

    #expect(
      resolved
        == .fragment([.text("first"), .text("second"), .text("third"), .text("fourth")]))
  }
}

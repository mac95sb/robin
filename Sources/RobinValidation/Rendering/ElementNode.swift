public struct ElementNode: Equatable, Sendable {
  public let name: ElementName
  public let attributes: [RenderAttribute]
  public let children: [RenderNode]

  public init(
    _ name: ElementName,
    attributes: [RenderAttribute] = [],
    @RenderBuilder children: () -> [RenderNode] = { [] }
  ) {
    self.name = name
    self.attributes = attributes
    self.children = children()
  }
}

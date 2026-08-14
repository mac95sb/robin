public indirect enum RenderNode: Equatable, Sendable {
  case element(ElementNode)
  case text(String)
  case fragment([RenderNode])
  case embed(EmbedNode)
}
